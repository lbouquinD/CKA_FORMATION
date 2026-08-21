package main

import (
	"errors"
	"io"
	"os"
	"path/filepath"
	"testing"

	"gopkg.in/yaml.v3"
)

func TestSetupManifests(t *testing.T) {
	files, err := filepath.Glob("../../exos/ckad-workloads/setups/*.yaml")
	if err != nil || len(files) == 0 {
		t.Fatalf("manifests introuvables: %v", err)
	}
	for _, path := range files {
		file, err := os.Open(path)
		if err != nil {
			t.Errorf("%s: %v", path, err)
			continue
		}
		decoder := yaml.NewDecoder(file)
		documents := 0
		for {
			var document map[string]any
			err = decoder.Decode(&document)
			if errors.Is(err, io.EOF) {
				break
			}
			if err != nil {
				t.Errorf("%s: YAML invalide: %v", path, err)
				break
			}
			if len(document) == 0 {
				continue
			}
			documents++
			if document["apiVersion"] == nil || document["kind"] == nil || document["metadata"] == nil {
				t.Errorf("%s: document Kubernetes incomplet", path)
			}
		}
		_ = file.Close()
		if documents == 0 {
			t.Errorf("%s: aucun document Kubernetes", path)
		}
	}
}
