package main

import "testing"

func TestValidID(t *testing.T) {
	valid := []string{"pod-01", "pod-13", "rs-03", "deploy-08", "ds-04", "sts-05"}
	for _, id := range valid {
		if !validID(id) {
			t.Fatalf("%s devrait être valide", id)
		}
	}
	invalid := []string{"pod-1", "pod-14", "rs-04", "deploy-00", "sts-06", "../pod-01"}
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
	}
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
		}
	}
}
