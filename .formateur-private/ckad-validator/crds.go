package main

import (
	"context"
	"os/exec"
	"strings"
	"time"
)

func crdVersion(o M, name string) M {
	for _, raw := range array(o, "spec", "versions") {
		item, _ := raw.(M)
		if text(item, "name") == name {
			return item
		}
	}
	return nil
}

func crdField(o M, version string, path ...string) M {
	full := []string{"schema", "openAPIV3Schema", "properties", "spec", "properties"}
	for i, part := range path {
		if i > 0 {
			full = append(full, "properties")
		}
		full = append(full, part)
	}
	field, _ := at(crdVersion(o, version), full...).(M)
	return field
}

func crdEstablished(o M) bool {
	for _, raw := range array(o, "status", "conditions") {
		item, _ := raw.(M)
		if text(item, "type") == "Established" {
			return text(item, "status") == "True"
		}
	}
	return false
}

func crdNames(o M, group, kind, plural, singular, shortName string) bool {
	if text(o, "spec", "group") != group || text(o, "spec", "names", "kind") != kind ||
		text(o, "spec", "names", "plural") != plural || text(o, "spec", "names", "singular") != singular {
		return false
	}
	for _, raw := range array(o, "spec", "names", "shortNames") {
		if fmtSprint(raw) == shortName {
			return true
		}
	}
	return false
}

func onlyStorageVersion(o M, name string) bool {
	versions := array(o, "spec", "versions")
	v := crdVersion(o, name)
	return len(versions) == 1 && text(v, "served") == "true" && text(v, "storage") == "true"
}

func requiredFields(o M, version string, fields ...string) bool {
	required := array(crdVersion(o, version), "schema", "openAPIV3Schema", "properties", "spec", "required")
	for _, field := range fields {
		if !containsAny(required, field) {
			return false
		}
	}
	return true
}

func enumValues(field M, values ...string) bool {
	enum := array(field, "enum")
	if len(enum) != len(values) {
		return false
	}
	for _, value := range values {
		if !containsAny(enum, value) {
			return false
		}
	}
	return true
}

func printerColumn(o M, version, name, kind, path string) bool {
	for _, raw := range array(crdVersion(o, version), "additionalPrinterColumns") {
		item, _ := raw.(M)
		if text(item, "name") == name && text(item, "type") == kind && text(item, "jsonPath") == path {
			return true
		}
	}
	return false
}

// serverAccepts soumet un manifeste en dry-run côté serveur : le schéma de la
// CRD est appliqué sans rien enregistrer.
func serverAccepts(manifest string) bool {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	cmd := exec.CommandContext(ctx, "kubectl", "apply", "--dry-run=server", "-n", namespace, "-f", "-")
	cmd.Stdin = strings.NewReader(manifest)
	return cmd.Run() == nil
}

func crdChecks() []check {
	switch exerciseID {
	case "crd-01":
		const crd = "geekheroes.crd01.ckad.io"
		return []check{
			noted("noms", "Le nom d'une CRD est <pluriel>.<groupe>. Sous spec.names se déclarent kind, plural, singular et shortNames. Ces champs ne se devinent pas, relisez l'énoncé.", func() bool {
				o, ok := object("crd", crd)
				return ok && crdNames(o, "crd01.ckad.io", "GeekHero", "geekheroes", "geekhero", "gk") &&
					text(o, "spec", "scope") == "Namespaced"
			}),
			noted("version", "Chaque entrée de spec.versions a served et storage. Une seule version peut être storage.", func() bool {
				o, ok := object("crd", crd)
				return ok && onlyStorageVersion(o, "v1")
			}),
			noted("schéma", "Le schéma openAPIV3Schema décrit spec.properties. Un nombre entier a le type integer. minimum et maximum se posent sur le champ.", func() bool {
				o, ok := object("crd", crd)
				level := crdField(o, "v1", "powerLevel")
				return ok && text(crdField(o, "v1", "universe"), "type") == "string" &&
					text(crdField(o, "v1", "specialPower"), "type") == "string" &&
					text(level, "type") == "integer" && text(level, "minimum") == "0" && text(level, "maximum") == "10000"
			}),
			noted("validation", "Testez votre CRD avec un objet hors bornes et kubectl apply --dry-run=server : l'API doit le refuser. Un objet correct doit passer.", func() bool {
				base := "apiVersion: crd01.ckad.io/v1\nkind: GeekHero\nmetadata:\n  name: probe\nspec:\n  universe: Test\n  specialPower: Test\n  powerLevel: "
				return serverAccepts(base+"500\n") && !serverAccepts(base+"15000\n") && !serverAccepts(base+"-1\n")
			}),
			noted("disponibilité", "Une CRD est utilisable quand sa condition Established vaut True. kubectl get gk doit répondre sans erreur.", func() bool {
				o, ok := object("crd", crd)
				return ok && crdEstablished(o)
			}),
		}
	case "crd-02":
		hero := func(name, universe, power string, level int) bool {
			o, ok := object("heroes.crd02.ckad.io", name)
			return ok && text(o, "spec", "universe") == universe && text(o, "spec", "specialPower") == power &&
				integer(o, "spec", "powerLevel") == level
		}
		return []check{
			noted("batman", "L'apiVersion d'un objet personnalisé est <groupe>/<version>. kubectl explain hero.spec et kubectl api-resources donnent les champs et le groupe.", func() bool {
				return hero("batman", "Comics", "Intellect & Martial Arts", 85)
			}),
			noted("gandalf", "Un nom d'objet est en minuscules. powerLevel est un entier : pas de guillemets dans le YAML.", func() bool {
				return hero("gandalf", "Fantasy", "Magic", 9000)
			}),
			noted("goku", "Respectez la casse et les espaces des valeurs texte. Une chaîne qui contient des espaces passe sans guillemets en YAML.", func() bool {
				return hero("goku", "Manga", "Super Saiyan", 9500)
			}),
			noted("suppression", "Un objet personnalisé se supprime comme les autres : kubectl delete <ressource> <nom>. Les noms courts fonctionnent aussi.", func() bool {
				_, exists := object("heroes.crd02.ckad.io", "saitama")
				return !exists
			}),
		}
	case "crd-03":
		const crd = "backups.crd03.ckad.io"
		return []check{
			noted("schéma", "Un nouveau champ s'ajoute sous spec.properties de la version. minimum se pose sur le champ entier.", func() bool {
				o, ok := object("crd", crd)
				retention := crdField(o, "v1", "retention")
				return ok && text(crdField(o, "v1", "schedule"), "type") == "string" &&
					text(retention, "type") == "integer" && text(retention, "minimum") == "1"
			}),
			noted("colonnes", "additionalPrinterColumns se déclare dans la version, avec name, type et jsonPath. jsonPath commence par un point.", func() bool {
				o, ok := object("crd", crd)
				return ok && printerColumn(o, "v1", "Schedule", "string", ".spec.schedule") &&
					printerColumn(o, "v1", "Retention", "integer", ".spec.retention")
			}),
			noted("objet", "Créez l'objet après la mise à jour de la CRD. Un champ inconnu du schéma est refusé ou supprimé à l'enregistrement.", func() bool {
				o, ok := object("backups.crd03.ckad.io", "nightly")
				return ok && text(o, "spec", "schedule") == "0 2 * * *" && integer(o, "spec", "retention") == 7
			}),
			noted("validation", "La borne minimum doit refuser une rétention nulle. Testez avec kubectl apply --dry-run=server.", func() bool {
				base := "apiVersion: crd03.ckad.io/v1\nkind: Backup\nmetadata:\n  name: probe\nspec:\n  schedule: \"* * * * *\"\n  retention: "
				return serverAccepts(base+"3\n") && !serverAccepts(base+"0\n")
			}),
		}
	case "crd-04":
		const crd = "widgets.crd04.ckad.io"
		return []check{
			noted("crd inchangée", "Le schéma de la CRD est le contrat. Corrigez le manifeste de l'objet, pas la CRD.", func() bool {
				o, ok := object("crd", crd)
				size := crdField(o, "v1", "size")
				return ok && onlyStorageVersion(o, "v1") && requiredFields(o, "v1", "size", "color") &&
					text(size, "type") == "integer" && text(size, "minimum") == "1" && text(size, "maximum") == "10" &&
					enumValues(crdField(o, "v1", "color"), "red", "green", "blue")
			}),
			noted("manifeste", "Corrigez le fichier fourni, à son emplacement. kubectl api-resources et kubectl explain widget.spec montrent la version servie et les champs.", func() bool {
				s, ok := fileContent("/tmp/ckad-crd-04/widget.yaml")
				return ok && strings.Contains(s, "crd04.ckad.io/v1") && !strings.Contains(s, "v1beta1") && !strings.Contains(s, "colour")
			}),
			noted("objet", "Lisez le message d'erreur de kubectl apply : il nomme la version inconnue, le champ inconnu et le type attendu.", func() bool {
				o, ok := object("widgets.crd04.ckad.io", "banner")
				return ok && integer(o, "spec", "size") == 3 && text(o, "spec", "color") == "blue" &&
					at(o, "spec", "colour") == nil
			}),
		}
	case "crd-05":
		const crd = "regions.crd05.ckad.io"
		return []check{
			noted("portée", "spec.scope vaut Namespaced ou Cluster. Une ressource Cluster n'a pas de namespace, comme un Node.", func() bool {
				o, ok := object("crd", crd)
				return ok && crdNames(o, "crd05.ckad.io", "Region", "regions", "region", "rg") &&
					text(o, "spec", "scope") == "Cluster" && onlyStorageVersion(o, "v1")
			}),
			noted("sous-ressource", "La sous-ressource status se déclare dans la version, sous subresources. Elle sépare l'écriture de spec et de status.", func() bool {
				o, ok := object("crd", crd)
				_, present := at(crdVersion(o, "v1"), "subresources", "status").(M)
				return ok && present
			}),
			noted("schéma", "Le champ code est une chaîne. pattern accepte une expression régulière.", func() bool {
				o, ok := object("crd", crd)
				code := crdField(o, "v1", "code")
				return ok && text(code, "type") == "string" && text(code, "pattern") == "^[a-z]{3}$"
			}),
			noted("objet", "Un objet d'une ressource Cluster se crée sans namespace. kubectl get rg le liste sans -n.", func() bool {
				o, ok := object("regions.crd05.ckad.io", "eu-west")
				return ok && text(o, "metadata", "namespace") == "" && text(o, "spec", "code") == "euw"
			}),
		}
	}
	return nil
}
