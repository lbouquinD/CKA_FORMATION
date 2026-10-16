package main

import (
	"encoding/base64"
	"os"
	"strings"
)

func secretValue(o M, key string) (string, bool) {
	raw := text(o, "data", key)
	if raw == "" {
		return "", false
	}
	decoded, err := base64.StdEncoding.DecodeString(raw)
	if err != nil {
		return "", false
	}
	return string(decoded), true
}

func fileMatchesSecret(o M, key, path string) bool {
	disk, err := os.ReadFile(path)
	if err != nil {
		return false
	}
	got, ok := secretValue(o, key)
	return ok && string(disk) == got
}

func tlsMaterial(o M) bool {
	crt, cok := secretValue(o, "tls.crt")
	key, kok := secretValue(o, "tls.key")
	return text(o, "type") == "kubernetes.io/tls" &&
		cok && kok &&
		strings.Contains(crt, "BEGIN CERTIFICATE") &&
		strings.Contains(key, "PRIVATE KEY")
}

func envSecretRef(c M, envName, secretName, key string) bool {
	for _, raw := range array(c, "env") {
		item, _ := raw.(M)
		if text(item, "name") == envName &&
			text(item, "valueFrom", "secretKeyRef", "name") == secretName &&
			text(item, "valueFrom", "secretKeyRef", "key") == key {
			return true
		}
	}
	return false
}

func joinedCommand(c M) string {
	if c == nil {
		return ""
	}
	return strings.Join(append(anyStrings(array(c, "command")), anyStrings(array(c, "args"))...), " ")
}

func aliveCommand(c M) bool {
	cmd := joinedCommand(c)
	return strings.Contains(cmd, "sleep") && strings.Contains(cmd, "3600")
}

func mountReadOnly(c M, name, path string) bool {
	for _, raw := range array(c, "volumeMounts") {
		item, _ := raw.(M)
		if text(item, "name") == name && normalizePath(text(item, "mountPath")) == normalizePath(path) {
			return text(item, "readOnly") == "true"
		}
	}
	return false
}

func secretProjection(v M, secretName string, keys ...string) bool {
	if v == nil || text(v, "secret", "secretName") != secretName {
		return false
	}
	found := map[string]string{}
	for _, raw := range array(v, "secret", "items") {
		item, _ := raw.(M)
		found[text(item, "key")] = text(item, "path")
	}
	if len(found) != len(keys) {
		return false
	}
	for _, key := range keys {
		if found[key] != key {
			return false
		}
	}
	return true
}

func mode0400(v M) bool {
	if integer(v, "secret", "defaultMode") == 256 {
		return true
	}
	items := array(v, "secret", "items")
	if len(items) == 0 {
		return false
	}
	for _, raw := range items {
		item, _ := raw.(M)
		if integer(item, "mode") != 256 {
			return false
		}
	}
	return true
}

func everyReadyContains(selector, container, path, fragment string) bool {
	items, ok := list("pods", selector)
	if !ok {
		return false
	}
	found := 0
	for _, item := range items {
		if !podReady(item) {
			continue
		}
		found++
		body, ok := execCat(text(item, "metadata", "name"), container, path)
		if !ok || !strings.Contains(body, fragment) {
			return false
		}
	}
	return found > 0
}

func secretChecks() []check {
	switch exerciseID {
	case "sec-01":
		return []check{
			noted("type", "kubectl create secret generic produit un Secret Opaque. Le contenu de data est encodé en base64 : ce n'est pas un chiffrement.", func() bool {
				o, ok := object("secret", "db-creds")
				return ok && text(o, "type") == "Opaque"
			}),
			noted("username", "Chaque --from-literal devient une clé. Décodez data pour comparer la valeur, kubectl get secret -o yaml montre seulement le base64.", func() bool {
				o, ok := object("secret", "db-creds")
				got, present := secretValue(o, "username")
				return ok && present && got == "dbadmin"
			}),
			noted("password", "La clé password se déclare à part de username. Une faute dans le littéral se voit après décodage base64.", func() bool {
				o, ok := object("secret", "db-creds")
				got, present := secretValue(o, "password")
				return ok && present && got == "Ck4d-db-91"
			}),
		}
	case "sec-02":
		return []check{
			noted("username", "Relancez lab.sh start si les fichiers de /tmp ont disparu. --from-file prend le nom du fichier comme clé et copie son contenu.", func() bool {
				o, ok := object("secret", "file-creds")
				return ok && text(o, "type") == "Opaque" && fileMatchesSecret(o, "username", "/tmp/ckad-sec-02/username")
			}),
			noted("password", "Passez chaque fichier avec --from-file. Le contenu stocké doit être celui du fichier, pas un littéral ressaisi à la main.", func() bool {
				o, ok := object("secret", "file-creds")
				return ok && fileMatchesSecret(o, "password", "/tmp/ckad-sec-02/password")
			}),
		}
	case "sec-03":
		return []check{
			noted("secret conservé", "Le Secret api-token est fourni par le scénario. Les Pods le consomment, ils ne le remplacent pas.", func() bool {
				o, ok := object("secret", "api-token")
				user, uok := secretValue(o, "user")
				token, tok := secretValue(o, "token")
				return ok && text(o, "type") == "Opaque" && uok && tok && user == "api" && token == "tok-8841"
			}),
			noted("variables", "valueFrom.secretKeyRef désigne le Secret et la clé. Le nom de la variable est indépendant du nom de la clé : envFrom les republierait sous leur nom d'origine.", func() bool {
				o, ok := object("pod", "client")
				c := container(o, "app")
				return ok && text(c, "image") == "busybox:1.36" && aliveCommand(c) &&
					envSecretRef(c, "API_USER", "api-token", "user") &&
					envSecretRef(c, "API_TOKEN", "api-token", "token")
			}),
			noted("disponibilité", "Un secretKeyRef vers une clé absente laisse le Pod en CreateContainerConfigError. La clé et le nom du Secret doivent exister.", func() bool {
				o, ok := object("pod", "client")
				return ok && podReady(o)
			}),
		}
	case "sec-04":
		return []check{
			noted("projection", "Le champ items choisit les clés et le nom de chaque fichier. Sans items, toutes les clés du Secret apparaissent dans le volume. Laissez la clé note dans le Secret.", func() bool {
				pod, ok := object("pod", "config-reader")
				secret, sok := object("secret", "app-config")
				note, nok := secretValue(secret, "note")
				return ok && sok && nok && note == "internal-only" &&
					secretProjection(getVolume(pod, "settings"), "app-config", "config.properties", "token")
			}),
			noted("droits", "readOnly se pose sur le volumeMount. defaultMode s'écrit souvent en octal dans le YAML : un nombre qui commence par 0 n'est pas lu en base 10. 0400 veut dire lecture pour le propriétaire.", func() bool {
				o, ok := object("pod", "config-reader")
				vol := getVolume(o, "settings")
				return ok && mode0400(vol) && mountReadOnly(container(o, "box"), "settings", "/etc/settings")
			}),
			noted("contenu", "Chaque clé projetée devient un fichier dans le montage. La clé laissée de côté ne doit pas avoir de fichier. Contrôlez le contenu dans le conteneur.", func() bool {
				props, pok := execCat("config-reader", "box", "/etc/settings/config.properties")
				token, tok := execCat("config-reader", "box", "/etc/settings/token")
				_, err := kubectl("exec", "-n", namespace, "config-reader", "-c", "box", "--", "sh", "-c", "test ! -e /etc/settings/note")
				return pok && tok && props == "mode=production" && token == "vol-token-12" && err == nil
			}),
			noted("disponibilité", "Le conteneur doit rester actif après le montage. Une image busybox se termine tout de suite si sa commande ne dort pas.", func() bool {
				o, ok := object("pod", "config-reader")
				c := container(o, "box")
				return ok && text(c, "image") == "busybox:1.36" && aliveCommand(c) && podReady(o)
			}),
		}
	case "sec-05":
		return []check{
			noted("type", "kubectl create secret tls fixe le type kubernetes.io/tls. Un Secret generic reste Opaque, même si on y copie les deux fichiers.", func() bool {
				o, ok := object("secret", "shop-tls")
				return ok && text(o, "type") == "kubernetes.io/tls"
			}),
			noted("certificat", "Le flag --cert alimente la clé tls.crt avec le fichier préparé par lab.sh start. Relancez la préparation si /tmp/ckad-sec-05 a été effacé.", func() bool {
				o, ok := object("secret", "shop-tls")
				return ok && fileMatchesSecret(o, "tls.crt", "/tmp/ckad-sec-05/tls.crt")
			}),
			noted("clé", "Le flag --key alimente tls.key. Les noms de clés d'un Secret TLS sont imposés : tls.crt et tls.key.", func() bool {
				o, ok := object("secret", "shop-tls")
				return ok && fileMatchesSecret(o, "tls.key", "/tmp/ckad-sec-05/tls.key")
			}),
		}
	case "sec-06":
		return []check{
			noted("secret tls", "Conservez le Secret web-tls fourni. Son type doit rester kubernetes.io/tls, avec un certificat et une clé privée.", func() bool {
				o, ok := object("secret", "web-tls")
				return ok && tlsMaterial(o)
			}),
			noted("montage", "Ajoutez un volume secret nommé certs, secretName web-tls, et un volumeMount en lecture seule sur /etc/nginx/certs. Le montage se déclare dans le conteneur.", func() bool {
				o, ok := object("deployment", "gateway")
				c := templateContainer(o, "nginx")
				vol := getVolume(templatePod(o), "certs")
				return ok && text(c, "image") == "nginx:1.27.3" &&
					vol != nil && text(vol, "secret", "secretName") == "web-tls" &&
					mountReadOnly(c, "certs", "/etc/nginx/certs")
			}),
			noted("fichiers", "Un Secret TLS projette tls.crt et tls.key. Attendez la fin du rollout : un Pod de l'ancienne révision n'a pas encore le volume.", func() bool {
				return everyReadyContains("app=gateway", "nginx", "/etc/nginx/certs/tls.crt", "BEGIN CERTIFICATE") &&
					everyReadyContains("app=gateway", "nginx", "/etc/nginx/certs/tls.key", "PRIVATE KEY")
			}),
			noted("disponibilité", "Gardez 2 réplicas, le label app=gateway et l'image nginx. kubectl rollout status confirme que les Pods à jour sont disponibles.", func() bool {
				o, ok := object("deployment", "gateway")
				return ok && rolloutComplete(o, 2) &&
					label(o, []string{"spec", "selector", "matchLabels"}, "app", "gateway") &&
					label(o, []string{"spec", "template", "metadata", "labels"}, "app", "gateway")
			}),
		}
	}
	return nil
}
