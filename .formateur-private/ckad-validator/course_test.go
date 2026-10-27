package main

import "testing"

func TestQuantities(t *testing.T) {
	if milli, ok := cpuMilli("100m"); !ok || milli != 100 {
		t.Fatalf("100m = %d %v", milli, ok)
	}
	if milli, ok := cpuMilli("1"); !ok || milli != 1000 {
		t.Fatalf("1 cpu = %d %v", milli, ok)
	}
	if !cpuEqual("1000m", "1") || !memEqual("64Mi", "67108864") {
		t.Fatal("les formes canoniques doivent être équivalentes")
	}
	if cpuEqual("", "100m") || memEqual("64Mi", "64M") {
		t.Fatal("une quantité vide ou décimale ne doit pas passer pour un Mio")
	}
	c := M{"resources": M{
		"requests": M{"cpu": "100m", "memory": "64Mi"},
		"limits":   M{"cpu": "0.2", "memory": "128Mi"},
	}}
	if !resourcesOK(c, "100m", "64Mi", "200m", "128Mi") {
		t.Fatal("requests et limits devraient correspondre")
	}
}

func TestSecretHelpers(t *testing.T) {
	secret := M{"data": M{"username": "YXBwdXNlcg=="}}
	got, ok := secretValue(secret, "username")
	if !ok || got != "appuser" {
		t.Fatalf("décodage secret: %q %v", got, ok)
	}
	volume := M{"secret": M{
		"secretName":  "app-config",
		"defaultMode": float64(256),
		"items": []any{
			M{"key": "token", "path": "token"},
			M{"key": "config.properties", "path": "config.properties"},
		},
	}}
	if !secretProjection(volume, "app-config", "config.properties", "token") || !mode0400(volume) {
		t.Fatal("la projection partielle devrait être acceptée")
	}
	if secretProjection(volume, "app-config", "config.properties", "token", "note") {
		t.Fatal("une clé absente des items ne doit pas passer")
	}
}

func TestAccessHelpers(t *testing.T) {
	// {"sub":"system:serviceaccount:ns:ci","aud":["vault"],"iat":100,"exp":7300}
	token := "eyJhbGciOiJub25lIn0.eyJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6bnM6Y2kiLCJhdWQiOlsidmF1bHQiXSwiaWF0IjoxMDAsImV4cCI6NzMwMH0.sig"
	claims, ok := jwtClaims(token)
	if !ok || text(claims, "sub") != "system:serviceaccount:ns:ci" || !claimAudience(claims, "vault") {
		t.Fatalf("claims JWT mal lues: %v %v", claims, ok)
	}
	if integer(claims, "exp")-integer(claims, "iat") != 7200 {
		t.Fatal("durée de vie du jeton incorrecte")
	}
	if _, ok := jwtClaims("pas-un-jwt"); ok {
		t.Fatal("une chaîne quelconque ne doit pas passer pour un JWT")
	}
	role := M{"rules": []any{
		M{"apiGroups": []any{"apps"}, "resources": []any{"deployments"}, "verbs": []any{"get", "list"}},
	}}
	if !roleGrants(role, "apps", "deployments", "get", "list") || roleGrants(role, "", "deployments", "get") {
		t.Fatal("le groupe d'API doit être pris en compte")
	}
	binding := M{
		"roleRef":  M{"kind": "Role", "name": "r"},
		"subjects": []any{M{"kind": "ServiceAccount", "name": "sa", "namespace": "default"}},
	}
	if bindingTargets(binding, "Role", "r", "sa", "ns") || !bindingTargets(binding, "Role", "r", "sa", "default") {
		t.Fatal("le namespace du subject doit être comparé")
	}
}

func TestCRDHelpers(t *testing.T) {
	crd := M{"spec": M{"versions": []any{M{
		"name": "v1", "served": true, "storage": true,
		"schema": M{"openAPIV3Schema": M{"properties": M{"spec": M{
			"required":   []any{"size"},
			"properties": M{"size": M{"type": "integer", "minimum": float64(1), "maximum": float64(10000)}},
		}}}},
		"additionalPrinterColumns": []any{M{"name": "Size", "type": "integer", "jsonPath": ".spec.size"}},
	}}}}
	size := crdField(crd, "v1", "size")
	if text(size, "type") != "integer" || text(size, "minimum") != "1" || text(size, "maximum") != "10000" {
		t.Fatalf("champ de schéma mal lu: %v", size)
	}
	if !onlyStorageVersion(crd, "v1") || !requiredFields(crd, "v1", "size") || requiredFields(crd, "v1", "color") {
		t.Fatal("versions ou champs requis mal lus")
	}
	if !printerColumn(crd, "v1", "Size", "integer", ".spec.size") {
		t.Fatal("colonne additionnelle non reconnue")
	}
}

func TestProbeHelpers(t *testing.T) {
	c := M{
		"readinessProbe": M{"tcpSocket": M{"port": float64(80)}, "periodSeconds": float64(5)},
		"livenessProbe": M{
			"exec":                M{"command": []any{"cat", "/tmp/healthy"}},
			"initialDelaySeconds": float64(5),
			"periodSeconds":       float64(10),
		},
		"startupProbe": M{
			"httpGet":          M{"path": "/", "port": float64(80)},
			"periodSeconds":    float64(5),
			"failureThreshold": float64(12),
		},
	}
	if !tcpProbe(c, "readinessProbe", 80, 5) {
		t.Fatal("sonde TCP non reconnue")
	}
	if !execProbe(c, "livenessProbe", 5, 10, "cat", "/tmp/healthy") {
		t.Fatal("sonde exec non reconnue")
	}
	if !httpProbe(c, "startupProbe", "/", 80, -1, 5, 12) {
		t.Fatal("startupProbe non reconnue")
	}
	if httpProbe(c, "startupProbe", "/healthz", 80, -1, 5, 12) {
		t.Fatal("un mauvais chemin ne doit pas passer")
	}
}
