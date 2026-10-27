package main

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"os/exec"
	"strings"
	"time"
)

func saUser(sa string) string {
	return "system:serviceaccount:" + namespace + ":" + sa
}

// canI interroge l'API au nom du ServiceAccount. kubectl auth can-i sort en
// erreur sur une réponse "no" : seule la sortie standard fait foi.
// "pods/log" serait lu comme le Pod nommé log : la sous-ressource passe par
// --subresource.
func canI(sa, verb, resource, ns string) (allowed bool, known bool) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	args := []string{"auth", "can-i", verb}
	if base, sub, found := strings.Cut(resource, "/"); found {
		args = append(args, base, "--subresource="+sub)
	} else {
		args = append(args, resource)
	}
	args = append(args, "--as="+saUser(sa))
	if ns != "" {
		args = append(args, "-n", ns)
	}
	out, _ := exec.CommandContext(ctx, "kubectl", args...).Output()
	switch strings.TrimSpace(string(out)) {
	case "yes":
		return true, true
	case "no":
		return false, true
	}
	return false, false
}

type access struct {
	verb, resource, ns string
	want               bool
}

func accessMatrix(sa string, rules ...access) bool {
	for _, rule := range rules {
		ns := rule.ns
		if ns == "" {
			ns = namespace
		}
		got, known := canI(sa, rule.verb, rule.resource, ns)
		if !known || got != rule.want {
			return false
		}
	}
	return true
}

func jwtClaims(token string) (M, bool) {
	parts := strings.Split(strings.TrimSpace(token), ".")
	if len(parts) != 3 {
		return nil, false
	}
	payload, err := base64.RawURLEncoding.DecodeString(strings.TrimRight(parts[1], "="))
	if err != nil {
		return nil, false
	}
	var claims M
	if json.Unmarshal(payload, &claims) != nil {
		return nil, false
	}
	return claims, true
}

func claimAudience(claims M, want string) bool {
	switch aud := claims["aud"].(type) {
	case string:
		return aud == want
	case []any:
		for _, item := range aud {
			if fmt.Sprint(item) == want {
				return true
			}
		}
	}
	return false
}

func serviceAccountExists(name string) bool {
	_, ok := object("serviceaccount", name)
	return ok
}

func podUsesSA(o M, sa string) bool {
	return text(o, "spec", "serviceAccountName") == sa
}

func projectedToken(v M, audience string, expiration int, path string) bool {
	for _, raw := range array(v, "projected", "sources") {
		source, _ := raw.(M)
		token, ok := source["serviceAccountToken"].(M)
		if ok && text(token, "audience") == audience &&
			integer(token, "expirationSeconds") == expiration &&
			text(token, "path") == path {
			return true
		}
	}
	return false
}

func everyReadyPodUsesSA(selector, sa string, count int) bool {
	items, ok := list("pods", selector)
	if !ok {
		return false
	}
	ready := 0
	for _, item := range items {
		if !podReady(item) {
			continue
		}
		if !podUsesSA(item, sa) {
			return false
		}
		ready++
	}
	return ready == count
}

func ruleAllows(rule M, group, resource string, verbs ...string) bool {
	if !containsAny(array(rule, "apiGroups"), group) || !containsAny(array(rule, "resources"), resource) {
		return false
	}
	for _, verb := range verbs {
		if !containsAny(array(rule, "verbs"), verb) {
			return false
		}
	}
	return true
}

func containsAny(values []any, want string) bool {
	for _, value := range values {
		if fmt.Sprint(value) == want || fmt.Sprint(value) == "*" {
			return true
		}
	}
	return false
}

func roleGrants(o M, group, resource string, verbs ...string) bool {
	for _, raw := range array(o, "rules") {
		rule, _ := raw.(M)
		if ruleAllows(rule, group, resource, verbs...) {
			return true
		}
	}
	return false
}

func bindingTargets(o M, roleKind, roleName, sa, saNamespace string) bool {
	if text(o, "roleRef", "kind") != roleKind || text(o, "roleRef", "name") != roleName {
		return false
	}
	for _, raw := range array(o, "subjects") {
		subject, _ := raw.(M)
		if text(subject, "kind") == "ServiceAccount" && text(subject, "name") == sa && text(subject, "namespace") == saNamespace {
			return true
		}
	}
	return false
}

func serviceAccountChecks() []check {
	switch exerciseID {
	case "sa-01":
		return []check{
			noted("serviceaccount", "Un ServiceAccount est un objet du namespace. kubectl create serviceaccount suffit, l'identité complète est system:serviceaccount:<namespace>:<nom>.", func() bool {
				return serviceAccountExists("build-bot")
			}),
			noted("pod", "Le Pod choisit son identité avec spec.serviceAccountName. Sans ce champ, il prend le ServiceAccount default. Ce champ ne se modifie pas sur un Pod existant : recréez-le.", func() bool {
				o, ok := object("pod", "builder")
				c := container(o, "builder")
				return ok && podUsesSA(o, "build-bot") && text(c, "image") == "busybox:1.36" && aliveCommand(c)
			}),
			noted("disponibilité", "Un Pod qui référence un ServiceAccount absent est refusé à la création. Créez d'abord le ServiceAccount, puis attendez Ready.", func() bool {
				o, ok := object("pod", "builder")
				return ok && podReady(o)
			}),
		}
	case "sa-02":
		return []check{
			noted("serviceaccount", "automountServiceAccountToken se pose au premier niveau du ServiceAccount, à côté de metadata. Il vaut true par défaut.", func() bool {
				o, ok := object("serviceaccount", "quiet-sa")
				return ok && text(o, "automountServiceAccountToken") == "false"
			}),
			noted("pod", "Le Pod doit utiliser ce ServiceAccount. Une valeur true posée dans le spec du Pod l'emporte sur celle du ServiceAccount.", func() bool {
				o, ok := object("pod", "no-token")
				c := container(o, "app")
				return ok && podUsesSA(o, "quiet-sa") && text(o, "spec", "automountServiceAccountToken") != "true" &&
					text(c, "image") == "busybox:1.36" && aliveCommand(c)
			}),
			noted("jeton absent", "Le jeton est monté sous /var/run/secrets/kubernetes.io/serviceaccount. Le réglage est lu à la création du Pod : un Pod créé avant reste monté.", func() bool {
				_, err := kubectl("exec", "-n", namespace, "no-token", "-c", "app", "--", "sh", "-c", "test ! -e /var/run/secrets/kubernetes.io/serviceaccount/token")
				return err == nil
			}),
			noted("disponibilité", "Le conteneur busybox doit rester actif. Attendez la condition Ready.", func() bool {
				o, ok := object("pod", "no-token")
				return ok && podReady(o)
			}),
		}
	case "sa-03":
		return []check{
			noted("serviceaccount", "Créez le ServiceAccount ci dans le namespace de l'exercice avant de lui demander un jeton.", func() bool {
				return serviceAccountExists("ci")
			}),
			noted("secret longue durée", "Depuis 1.24, aucun Secret de jeton n'est créé automatiquement. Un Secret de type kubernetes.io/service-account-token, annoté avec le nom du ServiceAccount, est rempli par le contrôleur.", func() bool {
				o, ok := object("secret", "ci-token")
				token, present := secretValue(o, "token")
				claims, cok := jwtClaims(token)
				return ok && present && cok && text(o, "type") == "kubernetes.io/service-account-token" &&
					text(o, "metadata", "annotations", "kubernetes.io/service-account.name") == "ci" &&
					text(claims, "sub") == saUser("ci")
			}),
			noted("jeton éphémère", "kubectl create token demande un jeton à l'API TokenRequest. Il n'est stocké nulle part : redirigez sa sortie vers le fichier demandé. --duration fixe sa durée de vie.", func() bool {
				s, ok := fileContent("/tmp/ckad-sa-03.txt")
				claims, cok := jwtClaims(s)
				life := integer(claims, "exp") - integer(claims, "iat")
				return ok && cok && text(claims, "sub") == saUser("ci") && life >= 7140 && life <= 7260
			}),
		}
	case "sa-04":
		return []check{
			noted("serviceaccount", "Le ServiceAccount reporter-sa doit exister dans le namespace avant le rollout, sinon le ReplicaSet ne crée aucun Pod.", func() bool {
				return serviceAccountExists("reporter-sa")
			}),
			noted("template", "Le ServiceAccount se change dans le template du Deployment. kubectl set serviceaccount le fait et déclenche un rollout. Gardez nom, image, label et réplicas.", func() bool {
				o, ok := object("deployment", "reporter")
				c := templateContainer(o, "reporter")
				return ok && text(o, "spec", "template", "spec", "serviceAccountName") == "reporter-sa" &&
					integer(o, "spec", "replicas") == 2 && selectorApp(o, "reporter") &&
					text(c, "image") == "busybox:1.36"
			}),
			noted("pods", "Les Pods existants gardent leur identité. Seuls les Pods recréés par le rollout utilisent le nouveau ServiceAccount : attendez la fin du rollout.", func() bool {
				o, ok := object("deployment", "reporter")
				return ok && rolloutComplete(o, 2) && everyReadyPodUsesSA("app=reporter", "reporter-sa", 2)
			}),
		}
	case "sa-05":
		return []check{
			noted("volume projeté", "Un volume projected accepte une source serviceAccountToken. audience, expirationSeconds et path se déclarent dans cette source.", func() bool {
				o, ok := object("pod", "audience-app")
				return ok && podUsesSA(o, "api-client") && projectedToken(getVolume(o, "vault-token"), "vault", 3600, "token")
			}),
			noted("montage", "Le volumeMount se déclare dans le conteneur, en lecture seule, sur le répertoire demandé. Le fichier prend le nom donné par path.", func() bool {
				o, ok := object("pod", "audience-app")
				c := container(o, "app")
				return ok && text(c, "image") == "busybox:1.36" && aliveCommand(c) && mountReadOnly(c, "vault-token", "/var/run/secrets/vault")
			}),
			noted("jeton", "Le kubelet écrit un JWT dont la claim aud reprend l'audience demandée et sub l'identité du ServiceAccount. Lisez le fichier dans le conteneur pour le vérifier.", func() bool {
				s, ok := execCat("audience-app", "app", "/var/run/secrets/vault/token")
				claims, cok := jwtClaims(s)
				return ok && cok && claimAudience(claims, "vault") && text(claims, "sub") == saUser("api-client")
			}),
			noted("disponibilité", "Attendez la condition Ready. Un ServiceAccount absent ou une expiration inférieure à 600 secondes bloque la création du Pod.", func() bool {
				o, ok := object("pod", "audience-app")
				return ok && podReady(o)
			}),
		}
	}
	return nil
}

func rbacChecks() []check {
	switch exerciseID {
	case "rbac-01":
		return []check{
			noted("role", "Un Role liste des règles : apiGroups, resources et verbs. Les Pods sont dans le groupe core, noté par une chaîne vide. Le nom de ressource est au pluriel.", func() bool {
				o, ok := object("role", "pod-reader")
				return ok && roleGrants(o, "", "pods", "get", "list", "watch")
			}),
			noted("binding", "Le RoleBinding relie roleRef (le Role) à des subjects. Un subject ServiceAccount porte son nom et son namespace.", func() bool {
				o, ok := object("rolebinding", "pod-reader-binding")
				return ok && serviceAccountExists("viewer") && bindingTargets(o, "Role", "pod-reader", "viewer", namespace)
			}),
			noted("droits effectifs", "kubectl auth can-i <verbe> <ressource> --as=system:serviceaccount:<ns>:<sa> -n <ns> teste les droits. Le ServiceAccount doit lire les Pods, sans pouvoir les modifier.", func() bool {
				return accessMatrix("viewer",
					access{"get", "pods", "", true},
					access{"list", "pods", "", true},
					access{"watch", "pods", "", true},
					access{"delete", "pods", "", false},
					access{"create", "pods", "", false},
				)
			}),
		}
	case "rbac-02":
		return []check{
			noted("role", "Les Deployments sont dans le groupe apps, pas dans le groupe core. Une règle peut couvrir plusieurs verbes, il en faut une par groupe.", func() bool {
				o, ok := object("role", "deployer")
				return ok &&
					roleGrants(o, "apps", "deployments", "get", "list", "create", "update", "patch", "delete") &&
					roleGrants(o, "", "pods", "get", "list")
			}),
			noted("binding", "Reliez le Role au ServiceAccount deployer du namespace de l'exercice avec un RoleBinding du même nom.", func() bool {
				o, ok := object("rolebinding", "deployer")
				return ok && serviceAccountExists("deployer") && bindingTargets(o, "Role", "deployer", "deployer", namespace)
			}),
			noted("droits effectifs", "Testez chaque verbe avec kubectl auth can-i. Sur les Pods, seule la lecture est permise, et les Secrets restent fermés.", func() bool {
				return accessMatrix("deployer",
					access{"create", "deployments.apps", "", true},
					access{"patch", "deployments.apps", "", true},
					access{"delete", "deployments.apps", "", true},
					access{"list", "pods", "", true},
					access{"delete", "pods", "", false},
					access{"get", "secrets", "", false},
				)
			}),
			noted("portée", "Un Role et un RoleBinding ne donnent des droits que dans leur namespace. Testez aussi un autre namespace avec -n.", func() bool {
				return accessMatrix("deployer", access{"create", "deployments.apps", "default", false})
			}),
		}
	case "rbac-03":
		return []check{
			noted("pods et logs", "Les logs sont la sous-ressource pods/log et exec est pods/exec. Une sous-ressource se déclare à part dans resources. Pour la tester : kubectl auth can-i get pods --subresource=log.", func() bool {
				return serviceAccountExists("log-reader") && accessMatrix("log-reader",
					access{"list", "pods", "", true},
					access{"get", "pods/log", "", true},
					access{"create", "pods/exec", "", false},
					access{"delete", "pods", "", false},
				)
			}),
			noted("secrets", "Chaque verbe s'accorde séparément. create ne donne ni get ni list.", func() bool {
				return accessMatrix("log-reader",
					access{"create", "secrets", "", true},
					access{"list", "secrets", "", false},
					access{"get", "secrets", "", false},
				)
			}),
			noted("namespaces", "Les Namespaces ne sont pas des objets d'un namespace. Il faut un ClusterRole et un ClusterRoleBinding aux noms demandés.", func() bool {
				cr, cok := object("clusterrole", "rbac-03-ns-lister")
				crb, bok := object("clusterrolebinding", "rbac-03-ns-lister")
				return cok && bok && roleGrants(cr, "", "namespaces", "list") &&
					bindingTargets(crb, "ClusterRole", "rbac-03-ns-lister", "log-reader", namespace) &&
					accessMatrix("log-reader",
						access{"list", "namespaces", "", true},
						access{"delete", "namespaces", "", false},
					)
			}),
			noted("portée", "Les droits sur les Pods et les Secrets restent limités au namespace. Ne les mettez pas dans le ClusterRole.", func() bool {
				return accessMatrix("log-reader",
					access{"list", "pods", "kube-system", false},
					access{"create", "secrets", "kube-system", false},
				)
			}),
		}
	case "rbac-04":
		return []check{
			noted("role", "Comparez le Role à la demande : groupe d'API, nom de ressource au pluriel, verbes. kubectl describe role affiche les règles sous forme de tableau.", func() bool {
				o, ok := object("role", "metrics-reader")
				return ok && roleGrants(o, "", "pods", "get", "list", "watch") && roleGrants(o, "", "services", "get", "list", "watch")
			}),
			noted("binding", "Un subject ServiceAccount désigne un compte d'un namespace précis. Le namespace du subject doit être celui où vit le ServiceAccount.", func() bool {
				o, ok := object("rolebinding", "metrics-reader")
				return ok && bindingTargets(o, "Role", "metrics-reader", "metrics", namespace)
			}),
			noted("droits effectifs", "Testez avec kubectl auth can-i --as. Lecture seule : aucun droit d'écriture ne doit apparaître.", func() bool {
				return serviceAccountExists("metrics") && accessMatrix("metrics",
					access{"list", "pods", "", true},
					access{"watch", "pods", "", true},
					access{"get", "services", "", true},
					access{"list", "services", "", true},
					access{"delete", "pods", "", false},
					access{"update", "services", "", false},
				)
			}),
		}
	case "rbac-05":
		return []check{
			noted("nœuds", "Les Nodes ne sont pas dans un namespace. Il faut un ClusterRole et un ClusterRoleBinding pour les lire.", func() bool {
				cr, cok := object("clusterrole", "rbac-05-node-viewer")
				crb, bok := object("clusterrolebinding", "rbac-05-node-viewer")
				return cok && bok && serviceAccountExists("inventory") &&
					roleGrants(cr, "", "nodes", "get", "list") &&
					bindingTargets(crb, "ClusterRole", "rbac-05-node-viewer", "inventory", namespace) &&
					accessMatrix("inventory",
						access{"list", "nodes", "", true},
						access{"delete", "nodes", "", false},
					)
			}),
			noted("rôle view", "Un RoleBinding peut référencer un ClusterRole. Les droits ne s'appliquent alors que dans le namespace du RoleBinding. Le ClusterRole view existe déjà.", func() bool {
				o, ok := object("rolebinding", "inventory-view")
				return ok && bindingTargets(o, "ClusterRole", "view", "inventory", namespace) &&
					accessMatrix("inventory",
						access{"list", "configmaps", "", true},
						access{"list", "deployments.apps", "", true},
					)
			}),
			noted("portée", "view ne donne pas les Secrets. Un ClusterRoleBinding vers view ouvrirait tous les namespaces : utilisez un RoleBinding.", func() bool {
				return accessMatrix("inventory",
					access{"get", "secrets", "", false},
					access{"list", "configmaps", "kube-system", false},
				)
			}),
		}
	case "rbac-06":
		questions := []access{
			{"list", "pods", "", true},
			{"delete", "pods", "", false},
			{"get", "secrets", "", true},
			{"list", "secrets", "", false},
			{"list", "deployments.apps", "", true},
			{"list", "deployments.apps", "kube-system", false},
		}
		return []check{
			noted("droits conservés", "Ne modifiez pas les droits d'auditor : l'exercice consiste à les lire. Relancez lab.sh start si le scénario a été changé.", func() bool {
				return accessMatrix("auditor", questions...)
			}),
			noted("format", "Une réponse par ligne, dans l'ordre des questions, en minuscules : yes ou no. kubectl auth can-i affiche déjà ce mot.", func() bool {
				s, ok := fileContent("/tmp/ckad-rbac-06.txt")
				lines := strings.Split(s, "\n")
				if !ok || len(lines) != len(questions) {
					return false
				}
				for _, line := range lines {
					if v := strings.TrimSpace(line); v != "yes" && v != "no" {
						return false
					}
				}
				return true
			}),
			noted("réponses", "Utilisez --as=system:serviceaccount:<ns>:auditor et le -n de chaque question. Un ClusterRole lié par RoleBinding ne vaut que dans ce namespace.", func() bool {
				s, ok := fileContent("/tmp/ckad-rbac-06.txt")
				lines := strings.Split(s, "\n")
				if !ok || len(lines) != len(questions) {
					return false
				}
				for i, q := range questions {
					want := "no"
					if q.want {
						want = "yes"
					}
					if strings.TrimSpace(lines[i]) != want {
						return false
					}
				}
				return true
			}),
		}
	}
	return nil
}
