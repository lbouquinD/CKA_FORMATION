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
