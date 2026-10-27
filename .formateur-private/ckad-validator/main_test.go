package main

import "testing"

func TestValidID(t *testing.T) {
	valid := []string{"pod-01", "pod-13", "rs-03", "deploy-08", "ds-04", "sts-05", "vol-01", "vol-08", "svc-01", "svc-12", "np-01", "np-06", "ing-01", "ing-06", "sec-01", "sec-06", "probe-01", "probe-05", "res-01", "res-05", "sa-01", "sa-05", "rbac-01", "rbac-06", "crd-01", "crd-05"}
	for _, id := range valid {
		if !validID(id) {
			t.Fatalf("%s devrait être valide", id)
		}
	}
	invalid := []string{"pod-1", "pod-14", "rs-04", "deploy-00", "sts-06", "vol-09", "svc-13", "np-07", "ing-07", "sec-07", "sec-1", "probe-06", "res-06", "sa-06", "rbac-07", "crd-06", "rbac-1", "../pod-01"}
	for _, id := range invalid {
		if validID(id) {
			t.Fatalf("%s ne devrait pas être valide", id)
		}
	}
}

func TestNavigationHelpers(t *testing.T) {
	value := M{
		"spec": M{
			"replicas": float64(3),
			"containers": []any{
				M{"name": "app", "image": "nginx:test"},
			},
		},
	}
	if integer(value, "spec", "replicas") != 3 {
		t.Fatal("conversion du nombre incorrecte")
	}
	if text(value, "spec", "containers", "0", "image") != "nginx:test" {
		t.Fatal("navigation dans un tableau incorrecte")
	}
	if text(container(value, "app"), "image") != "nginx:test" {
		t.Fatal("recherche du conteneur incorrecte")
	}
}

func TestCommandEquals(t *testing.T) {
	c := M{"command": []any{"sleep", "3600"}}
	if !commandEquals(c, "sleep", "3600") {
		t.Fatal("la commande devrait correspondre")
	}
	if commandEquals(c, "sleep", "10") {
		t.Fatal("la commande ne devrait pas correspondre")
	}
}

func TestHasMountIgnoresTrailingSlash(t *testing.T) {
	c := M{"volumeMounts": []any{
		M{"name": "shared-logs", "mountPath": "/var/log/shared/"},
	}}
	if !hasMount(c, "shared-logs", "/var/log/shared") {
		t.Fatal("le slash final ne devrait pas invalider le montage")
	}
	if hasMount(c, "shared-logs", "/var/log/other") {
		t.Fatal("un chemin différent ne devrait pas correspondre")
	}
}

func TestAllExercisesHaveChecks(t *testing.T) {
	ids := []string{
		"pod-01", "pod-02", "pod-03", "pod-04", "pod-05", "pod-06", "pod-07", "pod-08",
		"pod-09", "pod-10", "pod-11", "pod-12", "pod-13",
		"rs-01", "rs-02", "rs-03",
		"deploy-01", "deploy-02", "deploy-03", "deploy-04", "deploy-05", "deploy-06", "deploy-07", "deploy-08",
		"ds-01", "ds-02", "ds-03", "ds-04",
		"sts-01", "sts-02", "sts-03", "sts-04", "sts-05",
		"vol-01", "vol-02", "vol-03", "vol-04", "vol-05", "vol-06", "vol-07", "vol-08",
		"svc-01", "svc-02", "svc-03", "svc-04", "svc-05", "svc-06", "svc-07", "svc-08",
		"svc-09", "svc-10", "svc-11", "svc-12",
		"np-01", "np-02", "np-03", "np-04", "np-05", "np-06",
		"ing-01", "ing-02", "ing-03", "ing-04", "ing-05", "ing-06",
		"sec-01", "sec-02", "sec-03", "sec-04", "sec-05", "sec-06",
		"probe-01", "probe-02", "probe-03", "probe-04", "probe-05",
		"res-01", "res-02", "res-03", "res-04", "res-05",
		"sa-01", "sa-02", "sa-03", "sa-04", "sa-05",
		"rbac-01", "rbac-02", "rbac-03", "rbac-04", "rbac-05", "rbac-06",
		"crd-01", "crd-02", "crd-03", "crd-04", "crd-05",
	}
	used := map[string]bool{}
	for _, id := range ids {
		exerciseID = id
		namespace = "ckad-" + id
		checks := checksFor()
		if len(checks) == 0 {
			t.Errorf("%s ne possède aucun contrôle", id)
		}
		for _, item := range checks {
			if item.category == "" || item.run == nil {
				t.Errorf("%s possède un contrôle incomplet", id)
			}
			if hintFor(item.category) == "" {
				t.Errorf("%s / %s n'a pas de rappel", id, item.category)
			}
			used[id+"|"+item.category] = true
		}
	}
	for key := range legacyHints {
		if !used[key] {
			t.Errorf("rappel sans contrôle correspondant : %s", key)
		}
	}
}

func TestSelectsAllPods(t *testing.T) {
	if !selectsAllPods(M{"spec": M{"podSelector": M{}}}) {
		t.Fatal("un podSelector vide doit tout sélectionner")
	}
	if !selectsAllPods(M{"spec": M{"podSelector": M{"matchLabels": M{}}}}) {
		t.Fatal("un matchLabels vide doit tout sélectionner")
	}
	if selectsAllPods(M{"spec": M{"podSelector": M{"matchLabels": M{"app": "web"}}}}) {
		t.Fatal("un label ne doit pas sélectionner tout le namespace")
	}
}

func TestIngressPathIsExact(t *testing.T) {
	ingress := M{"spec": M{"rules": []any{
		M{"host": "shop.ckad.local", "http": M{"paths": []any{
			M{"path": "/", "pathType": "Prefix", "backend": M{"service": M{"name": "shop", "port": M{"number": float64(80)}}}},
			M{"path": "/api", "pathType": "Prefix", "backend": M{"service": M{"name": "api", "port": M{"number": float64(80)}}}},
		}}},
	}}}
	if !backendOK(findHTTPPath(ingress, "shop.ckad.local", "/api"), "api", 80) {
		t.Fatal("le chemin /api doit cibler api")
	}
	if backendOK(findHTTPPath(ingress, "shop.ckad.local", "/"), "api", 80) {
		t.Fatal("le chemin / ne doit pas être confondu avec /api")
	}
}
