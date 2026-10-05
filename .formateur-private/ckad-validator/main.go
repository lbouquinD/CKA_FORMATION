package main

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"sort"
	"strconv"
	"strings"
	"time"
)

type M = map[string]any
type check struct {
	category string
	run      func() bool
}

var exerciseID string
var namespace string

func kubectl(args ...string) ([]byte, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	cmd := exec.CommandContext(ctx, "kubectl", args...)
	return cmd.Output()
}

func object(kind, name string) (M, bool) {
	out, err := kubectl("get", kind, name, "-n", namespace, "-o", "json")
	if err != nil {
		return nil, false
	}
	var value M
	if json.Unmarshal(out, &value) != nil {
		return nil, false
	}
	return value, true
}

func list(kind string, labels ...string) ([]M, bool) {
	args := []string{"get", kind, "-n", namespace, "-o", "json"}
	if len(labels) > 0 && labels[0] != "" {
		args = append(args, "-l", labels[0])
	}
	out, err := kubectl(args...)
	if err != nil {
		return nil, false
	}
	var value struct {
		Items []M `json:"items"`
	}
	if json.Unmarshal(out, &value) != nil {
		return nil, false
	}
	return value.Items, true
}

func at(value any, path ...string) any {
	current := value
	for _, key := range path {
		switch typed := current.(type) {
		case M:
			current = typed[key]
		case []any:
			index, err := strconv.Atoi(key)
			if err != nil || index < 0 || index >= len(typed) {
				return nil
			}
			current = typed[index]
		default:
			return nil
		}
	}
	return current
}

func text(value any, path ...string) string {
	v := at(value, path...)
	if v == nil {
		return ""
	}
	return fmt.Sprint(v)
}

func integer(value any, path ...string) int {
	switch v := at(value, path...).(type) {
	case float64:
		return int(v)
	case int:
		return v
	case string:
		n, _ := strconv.Atoi(v)
		return n
	default:
		return 0
	}
}

func array(value any, path ...string) []any {
	v, _ := at(value, path...).([]any)
	return v
}

func container(obj M, name string) M {
	for _, raw := range array(obj, "spec", "containers") {
		item, _ := raw.(M)
		if text(item, "name") == name {
			return item
		}
	}
	return nil
}

func templateContainer(obj M, name string) M {
	template, _ := at(obj, "spec", "template").(M)
	wrapped := M{"spec": at(template, "spec")}
	if name == "" {
		containers := array(wrapped, "spec", "containers")
		if len(containers) > 0 {
			first, _ := containers[0].(M)
			return first
		}
		return nil
	}
	return container(wrapped, name)
}

func podReady(obj M) bool {
	for _, raw := range array(obj, "status", "conditions") {
		item, _ := raw.(M)
		if text(item, "type") == "Ready" {
			return text(item, "status") == "True"
		}
	}
	return false
}

func workloadReady(obj M, replicas int) bool {
	return integer(obj, "spec", "replicas") == replicas &&
		integer(obj, "status", "availableReplicas") == replicas
}

func label(obj M, path []string, key, value string) bool {
	labels, _ := at(obj, path...).(M)
	return text(labels, key) == value
}

func envValue(c M, name string) string {
	for _, raw := range array(c, "env") {
		item, _ := raw.(M)
		if text(item, "name") == name {
			return text(item, "value")
		}
	}
	return ""
}

func imageBusybox(c M) bool {
	img := text(c, "image")
	return img == "busybox" || strings.HasPrefix(img, "busybox:")
}

func envField(c M, name string) string {
	for _, raw := range array(c, "env") {
		item, _ := raw.(M)
		if text(item, "name") == name {
			return text(item, "valueFrom", "fieldRef", "fieldPath")
		}
	}
	return ""
}

func commandEquals(c M, expected ...string) bool {
	got := array(c, "command")
	if len(got) != len(expected) {
		return false
	}
	for i := range got {
		if fmt.Sprint(got[i]) != expected[i] {
			return false
		}
	}
	return true
}

func normalizePath(path string) string {
	if len(path) > 1 {
		return strings.TrimRight(path, "/")
	}
	return path
}

func hasMount(c M, name, path string) bool {
	for _, raw := range array(c, "volumeMounts") {
		m, _ := raw.(M)
		if text(m, "name") == name && normalizePath(text(m, "mountPath")) == normalizePath(path) {
			return true
		}
	}
	return false
}

func hasVolume(obj M, name, kind string) bool {
	for _, raw := range array(obj, "spec", "volumes") {
		v, _ := raw.(M)
		if text(v, "name") == name && at(v, kind) != nil {
			return true
		}
	}
	return false
}

func fileContent(path string) (string, bool) {
	data, err := os.ReadFile(path)
	return strings.TrimSpace(string(data)), err == nil
}

func names(items []M) []string {
	result := make([]string, 0, len(items))
	for _, item := range items {
		result = append(result, text(item, "metadata", "name"))
	}
	sort.Strings(result)
	return result
}

func fileHasNames(path string, expected []string) bool {
	content, ok := fileContent(path)
	if !ok {
		return false
	}
	sortedExpected := append([]string(nil), expected...)
	sort.Strings(sortedExpected)
	return content == strings.Join(sortedExpected, "\n")
}

func firstContainer(o M) M {
	cs := array(o, "spec", "containers")
	if len(cs) == 0 {
		return nil
	}
	m, _ := cs[0].(M)
	return m
}

func podChecks() []check {
	switch exerciseID {
	case "pod-01":
		return []check{
			{"ressource", func() bool {
				o, ok := object("pod", "web-dev")
				return ok && text(o, "metadata", "namespace") == namespace
			}},
			{"configuration", func() bool {
				o, ok := object("pod", "web-dev")
				c := firstContainer(o)
				return ok && len(array(o, "spec", "containers")) == 1 && text(c, "image") == "nginx:alpine" && label(o, []string{"metadata", "labels"}, "tier", "frontend") && envValue(c, "APP_ENV") == "development"
			}},
			{"disponibilité", func() bool { o, ok := object("pod", "web-dev"); return ok && podReady(o) }},
		}
	case "pod-02":
		return []check{
			{"annotation", func() bool {
				o, ok := object("pod", "web-dev")
				return ok && text(o, "metadata", "annotations", "builder") == "ansible"
			}},
			{"labels", func() bool {
				o, ok := object("pod", "web-dev")
				return ok && label(o, []string{"metadata", "labels"}, "tier", "ui") && label(o, []string{"metadata", "labels"}, "stage", "test")
			}},
			{"pod conservé", func() bool {
				o, ok := object("pod", "web-dev")
				c := firstContainer(o)
				return ok && text(c, "image") == "nginx:alpine" && envValue(c, "APP_ENV") == "development"
			}},
		}
	case "pod-03":
		return []check{
			{"liste avec labels", func() bool {
				s, ok := fileContent("/tmp/ckad-pod-03-labels.txt")
				return ok && strings.Contains(s, "web-dev") && strings.Contains(s, "api-dev") && (strings.Contains(s, "LABELS") || strings.Contains(s, "tier="))
			}},
			{"filtre", func() bool {
				s, ok := fileContent("/tmp/ckad-pod-03-ui.txt")
				return ok && strings.Contains(s, "web-dev") && !strings.Contains(s, "api-dev")
			}},
			{"yaml réutilisable", func() bool {
				s, ok := fileContent("/tmp/ckad-pod-03.yaml")
				return ok && strings.Contains(s, "web-dev") && strings.Contains(s, "nginx:alpine") && !strings.Contains(s, "uid:") && !strings.Contains(s, "resourceVersion:")
			}},
		}
	case "pod-04":
		return []check{
			{"configuration", func() bool {
				o, ok := object("pod", "box-check")
				c := firstContainer(o)
				cmd := strings.Join(append(anyStrings(array(c, "command")), anyStrings(array(c, "args"))...), " ")
				return ok && imageBusybox(c) && strings.Contains(cmd, "env") && strings.Contains(cmd, "sleep") && envValue(c, "DB_HOST") == "postgres" && envValue(c, "DB_PORT") == "5432"
			}},
			{"logs", func() bool {
				out, err := kubectl("logs", "-n", namespace, "box-check")
				if err != nil {
					return false
				}
				s := string(out)
				return strings.Contains(s, "DB_HOST=postgres") && strings.Contains(s, "DB_PORT=5432")
			}},
			{"disponibilité", func() bool { o, ok := object("pod", "box-check"); return ok && podReady(o) }},
		}
	case "pod-05":
		return []check{
			{"sélecteur", func() bool {
				labeled, ok := list("pods", "stage=test")
				_, web := object("pod", "web-dev")
				_, cache := object("pod", "cache-dev")
				return ok && len(labeled) == 0 && !web && !cache
			}},
			{"force", func() bool {
				_, box := object("pod", "box-check")
				return !box
			}},
		}
	case "pod-06":
		return []check{
			{"ressource", func() bool {
				o, ok := object("pod", "web-fast")
				return ok && text(o, "metadata", "namespace") == namespace
			}},
			{"configuration", func() bool {
				o, ok := object("pod", "web-fast")
				c := container(o, "nginx")
				return ok && len(array(o, "spec", "containers")) == 1 && c != nil && text(c, "image") == "nginx:1.27.3" && label(o, []string{"metadata", "labels"}, "app", "web-fast")
			}},
			{"disponibilité", func() bool { o, ok := object("pod", "web-fast"); return ok && podReady(o) }},
		}
	case "pod-07":
		return []check{
			{"métadonnées", func() bool {
				o, ok := object("pod", "api-limited")
				return ok && label(o, []string{"metadata", "labels"}, "app", "api") && label(o, []string{"metadata", "labels"}, "tier", "backend") && text(o, "metadata", "annotations", "training.ckad/owner") == "team-blue"
			}},
			{"ressources", func() bool {
				o, ok := object("pod", "api-limited")
				c := container(o, "api")
				return ok && text(c, "image") == "nginx:1.27.3" && text(c, "resources", "requests", "cpu") == "50m" && text(c, "resources", "requests", "memory") == "32Mi" && text(c, "resources", "limits", "cpu") == "100m" && text(c, "resources", "limits", "memory") == "64Mi" && text(o, "spec", "restartPolicy") == "Always"
			}},
			{"disponibilité", func() bool { o, ok := object("pod", "api-limited"); return ok && podReady(o) }},
		}
	case "pod-08":
		return []check{
			{"conteneurs", func() bool {
				o, ok := object("pod", "sidecar-logger")
				writer := container(o, "writer")
				reader := container(o, "reader")
				return ok && len(array(o, "spec", "containers")) == 2 && text(writer, "image") == "busybox:1.36" && strings.Contains(strings.Join(anyStrings(array(writer, "command")), " "), "date") && strings.Contains(strings.Join(anyStrings(array(writer, "command")), " "), "5") && text(reader, "image") == "busybox:1.36" && strings.Contains(strings.Join(anyStrings(array(reader, "command")), " "), "tail -F")
			}},
			{"volume partagé", func() bool {
				o, ok := object("pod", "sidecar-logger")
				return ok && hasVolume(o, "shared-logs", "emptyDir") && hasMount(container(o, "writer"), "shared-logs", "/var/log/shared") && hasMount(container(o, "reader"), "shared-logs", "/var/log/shared")
			}},
			{"comportement", func() bool {
				_, err := kubectl("exec", "-n", namespace, "sidecar-logger", "-c", "reader", "--", "test", "-s", "/var/log/shared/app.log")
				return err == nil
			}},
			{"disponibilité", func() bool { o, ok := object("pod", "sidecar-logger"); return ok && podReady(o) }},
		}
	case "pod-09":
		return []check{
			{"initialisation", func() bool {
				o, ok := object("pod", "initialized-web")
				init := M{}
				for _, raw := range array(o, "spec", "initContainers") {
					m, _ := raw.(M)
					if text(m, "name") == "prepare" {
						init = m
					}
				}
				return ok && text(init, "image") == "busybox:1.36" && hasMount(init, "web-content", "/work")
			}},
			{"volume partagé", func() bool {
				o, ok := object("pod", "initialized-web")
				return ok && hasVolume(o, "web-content", "emptyDir") && hasMount(container(o, "web"), "web-content", "/usr/share/nginx/html")
			}},
			{"contenu servi", func() bool {
				out, err := kubectl("exec", "-n", namespace, "initialized-web", "-c", "web", "--", "cat", "/usr/share/nginx/html/index.html")
				return err == nil && strings.Contains(string(out), "CKAD initialized")
			}},
			{"disponibilité", func() bool {
				o, ok := object("pod", "initialized-web")
				return ok && text(container(o, "web"), "image") == "nginx:1.27.3" && podReady(o)
			}},
		}
	case "pod-10":
		return []check{
			{"sonde readiness", func() bool {
				o, ok := object("pod", "probe-web")
				c := container(o, "web")
				return ok && text(c, "image") == "nginx:1.27.3" && integer(c, "ports", "0", "containerPort") == 80 && text(c, "readinessProbe", "httpGet", "path") == "/" && integer(c, "readinessProbe", "httpGet", "port") == 80 && integer(c, "readinessProbe", "initialDelaySeconds") == 2
			}},
			{"sonde liveness", func() bool {
				o, ok := object("pod", "probe-web")
				c := container(o, "web")
				return ok && text(c, "livenessProbe", "httpGet", "path") == "/" && integer(c, "livenessProbe", "httpGet", "port") == 80 && integer(c, "livenessProbe", "initialDelaySeconds") == 2
			}},
			{"disponibilité", func() bool { o, ok := object("pod", "probe-web"); return ok && podReady(o) }},
		}
	case "pod-11":
		return []check{
			{"configuration", func() bool {
				o, ok := object("pod", "looping-worker")
				c := container(o, "worker")
				return ok && text(c, "image") == "busybox:1.36" && strings.Contains(strings.Join(anyStrings(array(c, "command")), " "), "sleep 3600") && text(o, "spec", "restartPolicy") == "Always"
			}},
			{"stabilité", func() bool {
				o, ok := object("pod", "looping-worker")
				return ok && podReady(o) && integer(o, "status", "containerStatuses", "0", "restartCount") < 3
			}},
		}
	case "pod-12":
		return []check{
			{"image et commande", func() bool {
				o, ok := object("pod", "configured-app")
				c := container(o, "app")
				cmd := array(c, "command")
				return ok && text(c, "image") == "busybox:1.36" && len(cmd) >= 3 && fmt.Sprint(cmd[0]) == "sh" && fmt.Sprint(cmd[1]) == "-c" && strings.Contains(strings.Join(anyStrings(cmd[2:]), " "), "sleep")
			}},
			{"environnement", func() bool {
				o, ok := object("pod", "configured-app")
				c := container(o, "app")
				return ok && envValue(c, "APP_MODE") == "production" && envField(c, "POD_NAME") == "metadata.name"
			}},
			{"disponibilité", func() bool { o, ok := object("pod", "configured-app"); return ok && podReady(o) }},
		}
	case "pod-13":
		return []check{
			{"logs exportés", func() bool {
				s, ok := fileContent("/tmp/ckad-pod-13")
				return ok && strings.Contains(s, "CKAD-OPS-READY")
			}},
			{"inventaire", func() bool {
				s, ok := fileContent("/tmp/ckad-pod-13.txt")
				expected := "obsolete-pod busybox:1.36 Running\nops-reporter busybox:1.36 Running"
				return ok && s == expected
			}},
			{"suppression ciblée", func() bool {
				_, obsolete := object("pod", "obsolete-pod")
				reporter, ok := object("pod", "ops-reporter")
				return !obsolete && ok && podReady(reporter)
			}},
		}
	}
	return nil
}

func replicaSetChecks() []check {
	switch exerciseID {
	case "rs-01":
		return []check{
			{"configuration", func() bool {
				o, ok := object("replicaset", "frontend-rs")
				c := templateContainer(o, "nginx")
				return ok && workloadReady(o, 3) && label(o, []string{"spec", "selector", "matchLabels"}, "app", "frontend") && label(o, []string{"spec", "template", "metadata", "labels"}, "app", "frontend") && text(c, "image") == "nginx:1.27.3"
			}},
			{"pods gérés", func() bool { p, ok := list("pods", "app=frontend"); return ok && len(p) == 3 }},
		}
	case "rs-02":
		return []check{
			{"sélecteur", func() bool {
				o, ok := object("replicaset", "api-rs")
				return ok && label(o, []string{"spec", "selector", "matchLabels"}, "app", "api-v2") && label(o, []string{"spec", "template", "metadata", "labels"}, "app", "api-v2")
			}},
			{"configuration", func() bool {
				o, ok := object("replicaset", "api-rs")
				return ok && text(templateContainer(o, "api"), "image") == "nginx:1.27.3" && workloadReady(o, 3)
			}},
		}
	case "rs-03":
		return []check{
			{"mise à l'échelle", func() bool { o, ok := object("replicaset", "worker-rs"); return ok && workloadReady(o, 5) }},
			{"inventaire", func() bool {
				p, ok := list("pods", "app=worker")
				return ok && len(p) == 5 && fileHasNames("/tmp/ckad-rs-03.txt", names(p))
			}},
			{"auto-réparation", func() bool {
				baseline, bok := object("configmap", "rs03-baseline")
				pods, pok := list("pods", "app=worker")
				if !bok || !pok {
					return false
				}
				before := strings.Fields(text(baseline, "data", "pods"))
				after := names(pods)
				for _, oldName := range before {
					found := false
					for _, currentName := range after {
						found = found || oldName == currentName
					}
					if !found {
						return true
					}
				}
				return false
			}},
		}
	}
	return nil
}

func deploymentChecks() []check {
	switch exerciseID {
	case "deploy-01":
		return []check{
			{"configuration", func() bool {
				o, ok := object("deployment", "web")
				c := templateContainer(o, "nginx")
				return ok && workloadReady(o, 3) && label(o, []string{"spec", "selector", "matchLabels"}, "app", "web") && label(o, []string{"spec", "template", "metadata", "labels"}, "app", "web") && text(c, "image") == "nginx:1.27.3" && integer(c, "ports", "0", "containerPort") == 80
			}},
		}
	case "deploy-02":
		return []check{
			{"mise à l'échelle", func() bool { o, ok := object("deployment", "catalog"); return ok && workloadReady(o, 5) }},
			{"inventaire", func() bool {
				s, ok := fileContent("/tmp/ckad-deploy-02.txt")
				fields := strings.Fields(s)
				return ok && len(fields) == 4 && fields[0] == "catalog" && fields[1] == "5/5" && fields[2] == "5" && fields[3] == "5"
			}},
		}
	case "deploy-03":
		return []check{
			{"mise à jour", func() bool {
				o, ok := object("deployment", "storefront")
				return ok && text(templateContainer(o, "nginx"), "image") == "nginx:1.27.3" && text(o, "metadata", "annotations", "kubernetes.io/change-cause") == "upgrade to nginx 1.27.3"
			}},
			{"disponibilité", func() bool {
				o, ok := object("deployment", "storefront")
				return ok && workloadReady(o, 4) && integer(o, "metadata", "generation") == integer(o, "status", "observedGeneration")
			}},
		}
	case "deploy-04":
		return []check{
			{"révision restaurée", func() bool {
				o, ok := object("deployment", "payments")
				return ok && text(templateContainer(o, "payments"), "image") == "nginx:1.27.3"
			}},
			{"disponibilité", func() bool { o, ok := object("deployment", "payments"); return ok && workloadReady(o, 3) }},
			{"historique", func() bool { sets, ok := list("replicasets", "app=payments"); return ok && len(sets) >= 2 }},
		}
	case "deploy-05":
		return []check{
			{"stratégie", func() bool {
				o, ok := object("deployment", "critical-api")
				return ok && text(o, "spec", "strategy", "type") == "RollingUpdate" && text(o, "spec", "strategy", "rollingUpdate", "maxUnavailable") == "0" && text(o, "spec", "strategy", "rollingUpdate", "maxSurge") == "1" && integer(o, "spec", "revisionHistoryLimit") == 5
			}},
			{"configuration", func() bool {
				o, ok := object("deployment", "critical-api")
				return ok && text(templateContainer(o, "api"), "image") == "nginx:1.27.3" && label(o, []string{"spec", "selector", "matchLabels"}, "app", "critical-api") && workloadReady(o, 4)
			}},
		}
	case "deploy-06":
		return []check{
			{"image et démarrage", func() bool {
				o, ok := object("deployment", "broken-api")
				c := templateContainer(o, "api")
				return ok && text(c, "image") == "nginx:1.27.3" && len(array(c, "command")) == 0
			}},
			{"sonde", func() bool {
				o, ok := object("deployment", "broken-api")
				c := templateContainer(o, "api")
				return ok && text(c, "readinessProbe", "httpGet", "path") == "/" && integer(c, "readinessProbe", "httpGet", "port") == 80
			}},
			{"ressources", func() bool {
				o, ok := object("deployment", "broken-api")
				c := templateContainer(o, "api")
				return ok && text(c, "resources", "limits", "cpu") == "200m" && text(c, "resources", "limits", "memory") == "128Mi"
			}},
			{"disponibilité", func() bool { o, ok := object("deployment", "broken-api"); return ok && workloadReady(o, 3) }},
		}
	case "deploy-07":
		return []check{
			{"sélecteur", func() bool {
				o, ok := object("deployment", "orders")
				return ok && label(o, []string{"spec", "selector", "matchLabels"}, "app", "orders") && label(o, []string{"spec", "template", "metadata", "labels"}, "app", "orders")
			}},
			{"configuration", func() bool {
				o, ok := object("deployment", "orders")
				return ok && text(templateContainer(o, "orders"), "image") == "nginx:1.27.3" && workloadReady(o, 2)
			}},
		}
	case "deploy-08":
		return []check{
			{"stable", func() bool {
				o, ok := object("deployment", "frontend-stable")
				return ok && workloadReady(o, 4) && canaryLabels(o, "stable") && text(templateContainer(o, ""), "image") == "nginx:1.26.3"
			}},
			{"canary", func() bool {
				o, ok := object("deployment", "frontend-canary")
				return ok && workloadReady(o, 1) && canaryLabels(o, "canary") && text(templateContainer(o, ""), "image") == "nginx:1.27.3"
			}},
			{"inventaire", func() bool {
				return fileHasNames("/tmp/ckad-deploy-08.txt", []string{"frontend-canary", "frontend-stable"})
			}},
		}
	}
	return nil
}

func canaryLabels(o M, track string) bool {
	return label(o, []string{"spec", "selector", "matchLabels"}, "app", "frontend") &&
		label(o, []string{"spec", "selector", "matchLabels"}, "track", track) &&
		label(o, []string{"spec", "template", "metadata", "labels"}, "app", "frontend") &&
		label(o, []string{"spec", "template", "metadata", "labels"}, "track", track)
}

func daemonSetChecks() []check {
	switch exerciseID {
	case "ds-01":
		return []check{{"configuration", func() bool {
			o, ok := object("daemonset", "node-agent")
			c := templateContainer(o, "agent")
			return ok && label(o, []string{"spec", "selector", "matchLabels"}, "app", "node-agent") && label(o, []string{"spec", "template", "metadata", "labels"}, "app", "node-agent") && text(c, "image") == "busybox:1.36" && strings.Contains(strings.Join(anyStrings(array(c, "command")), " "), "sleep 3600") && daemonReady(o)
		}}}
	case "ds-02":
		return []check{
			{"ciblage", func() bool {
				o, ok := object("daemonset", "linux-collector")
				return ok && text(o, "spec", "template", "spec", "nodeSelector", "kubernetes.io/os") == "linux" && label(o, []string{"spec", "selector", "matchLabels"}, "app", "linux-collector") && label(o, []string{"spec", "template", "metadata", "labels"}, "app", "linux-collector")
			}},
			{"configuration", func() bool {
				o, ok := object("daemonset", "linux-collector")
				c := templateContainer(o, "collector")
				return ok && text(c, "image") == "busybox:1.36" && strings.Contains(strings.Join(anyStrings(array(c, "command")), " "), "sleep 3600")
			}},
			{"disponibilité", func() bool { o, ok := object("daemonset", "linux-collector"); return ok && daemonReady(o) }},
		}
	case "ds-03":
		return []check{{"tolérance", func() bool {
			o, ok := object("daemonset", "log-agent")
			if !ok {
				return false
			}
			for _, raw := range array(o, "spec", "template", "spec", "tolerations") {
				t, _ := raw.(M)
				if text(t, "key") == "dedicated" && text(t, "operator") == "Equal" && text(t, "value") == "observability" && text(t, "effect") == "NoSchedule" {
					return true
				}
			}
			return false
		}}, {"configuration conservée", func() bool {
			o, ok := object("daemonset", "log-agent")
			c := templateContainer(o, "agent")
			return ok && label(o, []string{"spec", "selector", "matchLabels"}, "app", "log-agent") && text(c, "image") == "busybox:1.36" && strings.Contains(strings.Join(anyStrings(array(c, "command")), " "), "sleep 3600")
		}}, {"disponibilité", func() bool { o, ok := object("daemonset", "log-agent"); return ok && daemonReady(o) }}}
	case "ds-04":
		return []check{
			{"stratégie", func() bool {
				o, ok := object("daemonset", "manual-agent")
				return ok && text(o, "spec", "updateStrategy", "type") == "OnDelete" && text(templateContainer(o, "agent"), "image") == "busybox:1.36"
			}},
			{"pods renouvelés", func() bool {
				p, ok := list("pods", "app=manual-agent")
				if !ok || len(p) == 0 {
					return false
				}
				for _, pod := range p {
					if text(container(pod, "agent"), "image") != "busybox:1.36" || !podReady(pod) {
						return false
					}
				}
				return fileHasNames("/tmp/ckad-ds-04.txt", names(p))
			}},
		}
	}
	return nil
}

func daemonReady(o M) bool {
	desired := integer(o, "status", "desiredNumberScheduled")
	return desired > 0 && integer(o, "status", "numberAvailable") == desired
}

func statefulSetChecks() []check {
	switch exerciseID {
	case "sts-01":
		return []check{
			{"service headless", func() bool {
				s, ok := object("service", "web-headless")
				return ok && text(s, "spec", "clusterIP") == "None" && text(s, "spec", "selector", "app") == "stateful-web" && integer(s, "spec", "ports", "0", "port") == 80
			}},
			{"statefulset", func() bool {
				o, ok := object("statefulset", "stateful-web")
				c := templateContainer(o, "nginx")
				return ok && text(o, "spec", "serviceName") == "web-headless" && label(o, []string{"spec", "selector", "matchLabels"}, "app", "stateful-web") && label(o, []string{"spec", "template", "metadata", "labels"}, "app", "stateful-web") && text(c, "image") == "nginx:1.27.3" && integer(c, "ports", "0", "containerPort") == 80 && statefulReady(o, 3)
			}},
			{"identités", func() bool { return podsExist("stateful-web", 3) }},
		}
	case "sts-02":
		return []check{
			{"service et ordre", func() bool {
				s, sok := object("service", "db-headless")
				o, ook := object("statefulset", "db")
				return sok && ook && text(s, "spec", "clusterIP") == "None" && text(o, "spec", "serviceName") == "db-headless" && text(o, "spec", "podManagementPolicy") == "OrderedReady"
			}},
			{"initialisation", func() bool {
				o, ok := object("statefulset", "db")
				init := M{}
				for _, raw := range array(o, "spec", "template", "spec", "initContainers") {
					m, _ := raw.(M)
					if text(m, "name") == "identity" {
						init = m
					}
				}
				c := templateContainer(o, "database")
				template := M{"spec": at(o, "spec", "template", "spec")}
				return ok && label(o, []string{"spec", "selector", "matchLabels"}, "app", "db") && label(o, []string{"spec", "template", "metadata", "labels"}, "app", "db") && text(init, "image") == "busybox:1.36" && hasMount(init, "data", "/data") && text(c, "image") == "busybox:1.36" && commandEquals(c, "sleep", "3600") && hasMount(c, "data", "/data") && hasVolume(template, "data", "emptyDir") && statefulReady(o, 3)
			}},
			{"identités", func() bool { return podsExist("db", 3) }},
		}
	case "sts-03":
		return []check{
			{"stockage", func() bool {
				o, ok := object("statefulset", "cache")
				if !ok {
					return false
				}
				claims := array(o, "spec", "volumeClaimTemplates")
				if len(claims) != 1 {
					return false
				}
				claim, _ := claims[0].(M)
				c := templateContainer(o, "cache")
				return text(o, "spec", "serviceName") == "cache-headless" && label(o, []string{"spec", "selector", "matchLabels"}, "app", "cache") && label(o, []string{"spec", "template", "metadata", "labels"}, "app", "cache") && text(c, "image") == "busybox:1.36" && commandEquals(c, "sleep", "3600") && text(claim, "metadata", "name") == "data" && text(claim, "spec", "storageClassName") == "local-path" && text(claim, "spec", "resources", "requests", "storage") == "100Mi" && text(claim, "spec", "accessModes", "0") == "ReadWriteOnce" && hasMount(c, "data", "/data")
			}},
			{"service headless", func() bool {
				s, ok := object("service", "cache-headless")
				return ok && text(s, "spec", "clusterIP") == "None" && text(s, "spec", "selector", "app") == "cache"
			}},
			{"persistance", func() bool {
				_, err := kubectl("exec", "-n", namespace, "cache-0", "-c", "cache", "--", "test", "-e", "/data/marker")
				return err == nil
			}},
			{"disponibilité", func() bool { o, ok := object("statefulset", "cache"); return ok && statefulReady(o, 2) }},
		}
	case "sts-04":
		return []check{
			{"stratégie", func() bool {
				o, ok := object("statefulset", "rolling-db")
				return ok && text(o, "spec", "updateStrategy", "type") == "RollingUpdate" && integer(o, "spec", "updateStrategy", "rollingUpdate", "partition") == 2 && text(templateContainer(o, "db"), "image") == "nginx:1.27.3"
			}},
			{"partition appliquée", func() bool {
				p0, a := object("pod", "rolling-db-0")
				p1, b := object("pod", "rolling-db-1")
				p2, c := object("pod", "rolling-db-2")
				p3, d := object("pod", "rolling-db-3")
				return a && b && c && d && text(container(p0, "db"), "image") == "nginx:1.26.3" && text(container(p1, "db"), "image") == "nginx:1.26.3" && text(container(p2, "db"), "image") == "nginx:1.27.3" && text(container(p3, "db"), "image") == "nginx:1.27.3"
			}},
			{"disponibilité", func() bool { o, ok := object("statefulset", "rolling-db"); return ok && statefulReady(o, 4) }},
		}
	case "sts-05":
		return []check{
			{"statefulset supprimé", func() bool { _, exists := object("statefulset", "sessions"); return !exists }},
			{"service conservé", func() bool {
				s, ok := object("service", "sessions-headless")
				return ok && text(s, "spec", "clusterIP") == "None" && text(s, "spec", "selector", "app") == "sessions"
			}},
			{"pods orphelins", func() bool {
				p, ok := list("pods", "app=sessions")
				if !ok || len(p) != 2 {
					return false
				}
				for _, pod := range p {
					if text(container(pod, "sessions"), "image") != "nginx:1.27.3" || !podReady(pod) || len(array(pod, "metadata", "ownerReferences")) != 0 {
						return false
					}
				}
				return fileHasNames("/tmp/ckad-sts-05.txt", names(p))
			}},
		}
	}
	return nil
}

func statefulReady(o M, replicas int) bool {
	return integer(o, "spec", "replicas") == replicas && integer(o, "status", "readyReplicas") == replicas
}

func podsExist(prefix string, count int) bool {
	for i := 0; i < count; i++ {
		p, ok := object("pod", fmt.Sprintf("%s-%d", prefix, i))
		if !ok || !podReady(p) {
			return false
		}
	}
	return true
}

func anyStrings(values []any) []string {
	result := make([]string, len(values))
	for i, value := range values {
		result[i] = fmt.Sprint(value)
	}
	return result
}

func getVolume(obj M, name string) M {
	for _, raw := range array(obj, "spec", "volumes") {
		v, _ := raw.(M)
		if text(v, "name") == name {
			return v
		}
	}
	return nil
}

func templatePod(obj M) M {
	return M{"spec": at(obj, "spec", "template", "spec")}
}

func hasPVCVolume(obj M, name, claim string) bool {
	v := getVolume(obj, name)
	return v != nil && text(v, "persistentVolumeClaim", "claimName") == claim
}

func hasConfigMapVolume(obj M, name, cm string) bool {
	v := getVolume(obj, name)
	return v != nil && text(v, "configMap", "name") == cm
}

func pvcBound(o M) bool {
	return text(o, "status", "phase") == "Bound"
}

func pvcSpecOK(name, storage, sc string) bool {
	o, ok := object("pvc", name)
	return ok && text(o, "spec", "storageClassName") == sc &&
		text(o, "spec", "resources", "requests", "storage") == storage &&
		text(o, "spec", "accessModes", "0") == "ReadWriteOnce"
}

func execCat(pod, container, path string) (string, bool) {
	out, err := kubectl("exec", "-n", namespace, pod, "-c", container, "--", "cat", path)
	if err != nil {
		return "", false
	}
	return strings.TrimSpace(string(out)), true
}

func firstLabeledPod(labelSelector string) (M, bool) {
	items, ok := list("pods", labelSelector)
	if !ok || len(items) == 0 {
		return nil, false
	}
	for _, item := range items {
		if podReady(item) {
			return item, true
		}
	}
	return items[0], true
}

func volumeChecks() []check {
	switch exerciseID {
	case "vol-01":
		return []check{
			{"ressource", func() bool {
				o, ok := object("pod", "scratch-box")
				return ok && text(o, "metadata", "namespace") == namespace && label(o, []string{"metadata", "labels"}, "app", "scratch")
			}},
			{"volume", func() bool {
				o, ok := object("pod", "scratch-box")
				c := container(o, "box")
				return ok && text(c, "image") == "busybox:1.36" && hasVolume(o, "scratch", "emptyDir") && hasMount(c, "scratch", "/scratch")
			}},
			{"contenu", func() bool {
				s, ok := execCat("scratch-box", "box", "/scratch/ready.txt")
				return ok && s == "CKAD-VOL"
			}},
			{"disponibilité", func() bool {
				o, ok := object("pod", "scratch-box")
				return ok && podReady(o)
			}},
		}
	case "vol-02":
		return []check{
			{"ressource", func() bool {
				o, ok := object("pod", "ram-box")
				return ok && label(o, []string{"metadata", "labels"}, "app", "ram")
			}},
			{"volume mémoire", func() bool {
				o, ok := object("pod", "ram-box")
				c := container(o, "box")
				v := getVolume(o, "cache")
				return ok && text(c, "image") == "busybox:1.36" && hasMount(c, "cache", "/cache") &&
					text(v, "emptyDir", "medium") == "Memory" && text(v, "emptyDir", "sizeLimit") == "32Mi"
			}},
			{"contenu", func() bool {
				s, ok := execCat("ram-box", "box", "/cache/ready.txt")
				return ok && s == "CKAD-RAM"
			}},
			{"disponibilité", func() bool {
				o, ok := object("pod", "ram-box")
				return ok && podReady(o)
			}},
		}
	case "vol-03":
		return []check{
			{"deployment", func() bool {
				o, ok := object("deployment", "share-html")
				return ok && workloadReady(o, 1) &&
					label(o, []string{"spec", "selector", "matchLabels"}, "app", "share-html") &&
					label(o, []string{"spec", "template", "metadata", "labels"}, "app", "share-html")
			}},
			{"volume partagé", func() bool {
				o, ok := object("deployment", "share-html")
				spec := templatePod(o)
				loader := templateContainer(o, "loader")
				web := templateContainer(o, "web")
				return ok && hasVolume(spec, "html", "emptyDir") &&
					text(loader, "image") == "busybox:1.36" && hasMount(loader, "html", "/work") &&
					text(web, "image") == "nginx:1.27.3" && hasMount(web, "html", "/usr/share/nginx/html")
			}},
			{"contenu", func() bool {
				p, ok := firstLabeledPod("app=share-html")
				if !ok {
					return false
				}
				s, cok := execCat(text(p, "metadata", "name"), "web", "/usr/share/nginx/html/index.html")
				return cok && strings.Contains(s, "CKAD shared volume")
			}},
		}
	case "vol-04":
		return []check{
			{"pvc", func() bool {
				o, ok := object("pvc", "app-data")
				return ok && pvcSpecOK("app-data", "50Mi", "local-path") && pvcBound(o)
			}},
			{"pod", func() bool {
				o, ok := object("pod", "app-storage")
				c := container(o, "app")
				return ok && label(o, []string{"metadata", "labels"}, "app", "storage") &&
					text(c, "image") == "busybox:1.36" && hasPVCVolume(o, "data", "app-data") &&
					hasMount(c, "data", "/data")
			}},
			{"disponibilité", func() bool {
				o, ok := object("pod", "app-storage")
				return ok && podReady(o)
			}},
		}
	case "vol-05":
		return []check{
			{"pvc", func() bool {
				o, ok := object("pvc", "keep-data")
				return ok && pvcSpecOK("keep-data", "100Mi", "local-path") && pvcBound(o)
			}},
			{"pod", func() bool {
				o, ok := object("pod", "keep-pod")
				c := container(o, "app")
				return ok && text(c, "image") == "busybox:1.36" && hasPVCVolume(o, "data", "keep-data") &&
					hasMount(c, "data", "/data") && podReady(o)
			}},
			{"persistance", func() bool {
				s, ok := execCat("keep-pod", "app", "/data/marker")
				return ok && s == "persisted"
			}},
		}
	case "vol-06":
		return []check{
			{"configmap conservé", func() bool {
				o, ok := object("configmap", "app-config")
				return ok && strings.Contains(text(o, "data", "app.conf"), "listen=8080")
			}},
			{"volume", func() bool {
				o, ok := object("pod", "config-reader")
				c := container(o, "reader")
				return ok && label(o, []string{"metadata", "labels"}, "app", "config") &&
					text(c, "image") == "busybox:1.36" && hasConfigMapVolume(o, "config", "app-config") &&
					hasMount(c, "config", "/etc/app")
			}},
			{"contenu", func() bool {
				s, ok := execCat("config-reader", "reader", "/etc/app/app.conf")
				return ok && strings.Contains(s, "listen=8080")
			}},
			{"disponibilité", func() bool {
				o, ok := object("pod", "config-reader")
				return ok && podReady(o)
			}},
		}
	case "vol-07":
		return []check{
			{"pvc", func() bool {
				o, ok := object("pvc", "broken-data")
				return ok && pvcSpecOK("broken-data", "100Mi", "local-path") && pvcBound(o)
			}},
			{"pod", func() bool {
				o, ok := object("pod", "data-writer")
				c := container(o, "writer")
				return ok && text(c, "image") == "busybox:1.36" && hasPVCVolume(o, "data", "broken-data") &&
					hasMount(c, "data", "/data") && podReady(o)
			}},
			{"contenu", func() bool {
				s, ok := execCat("data-writer", "writer", "/data/ok")
				return ok && s == "fixed"
			}},
		}
	case "vol-08":
		return []check{
			{"pvc", func() bool {
				o, ok := object("pvc", "web-content")
				return ok && pvcSpecOK("web-content", "50Mi", "local-path") && pvcBound(o)
			}},
			{"deployment", func() bool {
				o, ok := object("deployment", "static-web")
				c := templateContainer(o, "nginx")
				spec := templatePod(o)
				return ok && workloadReady(o, 1) &&
					label(o, []string{"spec", "selector", "matchLabels"}, "app", "static-web") &&
					label(o, []string{"spec", "template", "metadata", "labels"}, "app", "static-web") &&
					text(c, "image") == "nginx:1.27.3" && hasPVCVolume(spec, "content", "web-content") &&
					hasMount(c, "content", "/usr/share/nginx/html")
			}},
			{"contenu", func() bool {
				p, ok := firstLabeledPod("app=static-web")
				if !ok {
					return false
				}
				s, cok := execCat(text(p, "metadata", "name"), "nginx", "/usr/share/nginx/html/index.html")
				return cok && s == "CKAD pvc web"
			}},
		}
	}
	return nil
}

func serviceTypeOf(o M) string {
	if t := text(o, "spec", "type"); t != "" {
		return t
	}
	return "ClusterIP"
}

func selectorEmpty(o M) bool {
	sel := at(o, "spec", "selector")
	if sel == nil {
		return true
	}
	labels, ok := sel.(M)
	return ok && len(labels) == 0
}

func servicePortByName(o M, name string) M {
	for _, raw := range array(o, "spec", "ports") {
		port, _ := raw.(M)
		if text(port, "name") == name {
			return port
		}
	}
	return nil
}

func readyEndpointCount(name string) int {
	o, ok := object("endpoints", name)
	if !ok {
		return 0
	}
	count := 0
	for _, raw := range array(o, "subsets") {
		subset, _ := raw.(M)
		count += len(array(subset, "addresses"))
	}
	return count
}

func endpointHasPort(name string, want int) bool {
	o, ok := object("endpoints", name)
	if !ok {
		return false
	}
	for _, raw := range array(o, "subsets") {
		subset, _ := raw.(M)
		for _, rawPort := range array(subset, "ports") {
			port, _ := rawPort.(M)
			if integer(port, "port") == want {
				return true
			}
		}
	}
	return false
}

func endpointHasIP(name, ip string) bool {
	o, ok := object("endpoints", name)
	if !ok {
		return false
	}
	for _, raw := range array(o, "subsets") {
		subset, _ := raw.(M)
		for _, rawAddr := range array(subset, "addresses") {
			addr, _ := rawAddr.(M)
			if text(addr, "ip") == ip {
				return true
			}
		}
	}
	return false
}

func endpointPodNames(name string) []string {
	o, ok := object("endpoints", name)
	if !ok {
		return nil
	}
	var result []string
	for _, raw := range array(o, "subsets") {
		subset, _ := raw.(M)
		for _, rawAddr := range array(subset, "addresses") {
			addr, _ := rawAddr.(M)
			if podName := text(addr, "targetRef", "name"); podName != "" {
				result = append(result, podName)
			}
		}
	}
	sort.Strings(result)
	return result
}

func labeledPodNames(labelSelector string) []string {
	items, ok := list("pods", labelSelector)
	if !ok {
		return nil
	}
	return names(items)
}

func sameNames(left, right []string) bool {
	if len(left) != len(right) {
		return false
	}
	for i := range left {
		if left[i] != right[i] {
			return false
		}
	}
	return true
}

func selectorEquals(o M, expected map[string]string) bool {
	sel, _ := at(o, "spec", "selector").(M)
	if len(sel) != len(expected) {
		return false
	}
	for key, value := range expected {
		if text(sel, key) != value {
			return false
		}
	}
	return true
}

func serviceChecks() []check {
	switch exerciseID {
	case "svc-01":
		return []check{
			{"deployment", func() bool {
				o, ok := object("deployment", "web")
				c := templateContainer(o, "nginx")
				return ok && workloadReady(o, 2) &&
					label(o, []string{"spec", "selector", "matchLabels"}, "app", "web") &&
					label(o, []string{"spec", "template", "metadata", "labels"}, "app", "web") &&
					text(c, "image") == "nginx:1.27.3" && integer(c, "ports", "0", "containerPort") == 80
			}},
			{"service", func() bool {
				o, ok := object("service", "web")
				return ok && serviceTypeOf(o) == "ClusterIP" &&
					text(o, "spec", "selector", "app") == "web" &&
					integer(o, "spec", "ports", "0", "port") == 80 &&
					integer(o, "spec", "ports", "0", "targetPort") == 80
			}},
			{"endpoints", func() bool {
				return readyEndpointCount("web") == 2 && endpointHasPort("web", 80)
			}},
		}
	case "svc-02":
		return []check{
			{"service", func() bool {
				o, ok := object("service", "api-node")
				return ok && serviceTypeOf(o) == "NodePort" &&
					text(o, "spec", "selector", "app") == "api" &&
					integer(o, "spec", "ports", "0", "port") == 80 &&
					integer(o, "spec", "ports", "0", "targetPort") == 80 &&
					integer(o, "spec", "ports", "0", "nodePort") == 30080
			}},
			{"endpoints", func() bool {
				return readyEndpointCount("api-node") == 2 && endpointHasPort("api-node", 80)
			}},
			{"deployment conservé", func() bool {
				o, ok := object("deployment", "api")
				return ok && workloadReady(o, 2) && text(templateContainer(o, "nginx"), "image") == "nginx:1.27.3"
			}},
		}
	case "svc-03":
		return []check{
			{"sélecteur", func() bool {
				o, ok := object("service", "shop")
				return ok && text(o, "spec", "selector", "app") == "shop" &&
					serviceTypeOf(o) == "ClusterIP" &&
					integer(o, "spec", "ports", "0", "port") == 80 &&
					integer(o, "spec", "ports", "0", "targetPort") == 80
			}},
			{"endpoints", func() bool {
				return readyEndpointCount("shop") == 2 && endpointHasPort("shop", 80)
			}},
			{"deployment conservé", func() bool {
				o, ok := object("deployment", "shop")
				return ok && workloadReady(o, 2) &&
					label(o, []string{"spec", "selector", "matchLabels"}, "app", "shop")
			}},
		}
	case "svc-04":
		return []check{
			{"ports nommés", func() bool {
				o, ok := object("service", "gateway")
				httpPort := servicePortByName(o, "http")
				adminPort := servicePortByName(o, "admin")
				return ok && serviceTypeOf(o) == "ClusterIP" &&
					text(o, "spec", "selector", "app") == "gateway" &&
					integer(httpPort, "port") == 80 && integer(httpPort, "targetPort") == 80 &&
					integer(adminPort, "port") == 8080 && integer(adminPort, "targetPort") == 80
			}},
			{"endpoints", func() bool {
				return readyEndpointCount("gateway") == 1 && endpointHasPort("gateway", 80)
			}},
		}
	case "svc-05":
		return []check{
			{"targetPort nommé", func() bool {
				o, ok := object("service", "named-web")
				return ok && serviceTypeOf(o) == "ClusterIP" &&
					text(o, "spec", "selector", "app") == "named-web" &&
					integer(o, "spec", "ports", "0", "port") == 80 &&
					text(o, "spec", "ports", "0", "targetPort") == "web"
			}},
			{"endpoints", func() bool {
				return readyEndpointCount("named-web") == 1 && endpointHasPort("named-web", 80)
			}},
		}
	case "svc-06":
		return []check{
			{"service", func() bool {
				o, ok := object("service", "legacy-db")
				return ok && serviceTypeOf(o) == "ClusterIP" && selectorEmpty(o) &&
					integer(o, "spec", "ports", "0", "port") == 5432 &&
					integer(o, "spec", "ports", "0", "targetPort") == 5432
			}},
			{"endpoints", func() bool {
				return endpointHasIP("legacy-db", "192.0.2.10") && endpointHasPort("legacy-db", 5432)
			}},
		}
	case "svc-07":
		return []check{
			{"deployment", func() bool {
				o, ok := object("deployment", "members")
				c := templateContainer(o, "app")
				return ok && workloadReady(o, 2) &&
					label(o, []string{"spec", "selector", "matchLabels"}, "app", "members") &&
					label(o, []string{"spec", "template", "metadata", "labels"}, "app", "members") &&
					text(c, "image") == "busybox:1.36" &&
					strings.Contains(strings.Join(anyStrings(array(c, "command")), " "), "sleep 3600")
			}},
			{"headless", func() bool {
				o, ok := object("service", "members")
				return ok && text(o, "spec", "clusterIP") == "None" &&
					text(o, "spec", "selector", "app") == "members" &&
					integer(o, "spec", "ports", "0", "port") == 80
			}},
			{"endpoints", func() bool { return readyEndpointCount("members") == 2 }},
		}
	case "svc-08":
		return []check{
			{"targetPort", func() bool {
				o, ok := object("service", "payments")
				return ok && serviceTypeOf(o) == "ClusterIP" &&
					text(o, "spec", "selector", "app") == "payments" &&
					integer(o, "spec", "ports", "0", "port") == 80 &&
					integer(o, "spec", "ports", "0", "targetPort") == 80
			}},
			{"endpoints", func() bool {
				return readyEndpointCount("payments") == 2 && endpointHasPort("payments", 80) && !endpointHasPort("payments", 9090)
			}},
		}
	case "svc-09":
		return []check{
			{"loadbalancer", func() bool {
				o, ok := object("service", "public-lb")
				return ok && serviceTypeOf(o) == "LoadBalancer" &&
					text(o, "spec", "selector", "app") == "public" &&
					integer(o, "spec", "ports", "0", "port") == 80 &&
					integer(o, "spec", "ports", "0", "targetPort") == 80
			}},
			{"endpoints", func() bool {
				return readyEndpointCount("public-lb") == 2 && endpointHasPort("public-lb", 80)
			}},
			{"deployment conservé", func() bool {
				o, ok := object("deployment", "public")
				return ok && workloadReady(o, 2)
			}},
		}
	case "svc-10":
		return []check{
			{"loadbalancer", func() bool {
				o, ok := object("service", "edge")
				return ok && serviceTypeOf(o) == "LoadBalancer" &&
					text(o, "spec", "selector", "app") == "edge" &&
					integer(o, "spec", "ports", "0", "port") == 80 &&
					integer(o, "spec", "ports", "0", "targetPort") == 80
			}},
			{"endpoints", func() bool {
				return readyEndpointCount("edge") == 2 && endpointHasPort("edge", 80)
			}},
		}
	case "svc-11":
		return []check{
			{"stable", func() bool {
				o, ok := object("deployment", "catalog-stable")
				return ok && workloadReady(o, 3) &&
					label(o, []string{"spec", "selector", "matchLabels"}, "app", "catalog") &&
					label(o, []string{"spec", "selector", "matchLabels"}, "track", "stable") &&
					label(o, []string{"spec", "template", "metadata", "labels"}, "app", "catalog") &&
					label(o, []string{"spec", "template", "metadata", "labels"}, "track", "stable") &&
					text(templateContainer(o, "nginx"), "image") == "nginx:1.26.3"
			}},
			{"canary", func() bool {
				o, ok := object("deployment", "catalog-canary")
				return ok && workloadReady(o, 1) &&
					label(o, []string{"spec", "selector", "matchLabels"}, "app", "catalog") &&
					label(o, []string{"spec", "selector", "matchLabels"}, "track", "canary") &&
					label(o, []string{"spec", "template", "metadata", "labels"}, "app", "catalog") &&
					label(o, []string{"spec", "template", "metadata", "labels"}, "track", "canary") &&
					text(templateContainer(o, "nginx"), "image") == "nginx:1.27.3"
			}},
			{"service", func() bool {
				o, ok := object("service", "catalog")
				return ok && serviceTypeOf(o) == "ClusterIP" &&
					selectorEquals(o, map[string]string{"app": "catalog"}) &&
					integer(o, "spec", "ports", "0", "port") == 80 &&
					integer(o, "spec", "ports", "0", "targetPort") == 80 &&
					readyEndpointCount("catalog") == 4
			}},
		}
	case "svc-12":
		return []check{
			{"bascule", func() bool {
				o, ok := object("service", "catalog")
				return ok && serviceTypeOf(o) == "ClusterIP" &&
					selectorEquals(o, map[string]string{"app": "catalog", "version": "green"}) &&
					integer(o, "spec", "ports", "0", "port") == 80 &&
					integer(o, "spec", "ports", "0", "targetPort") == 80
			}},
			{"trafic vert", func() bool {
				green := labeledPodNames("app=catalog,version=green")
				return len(green) == 2 && sameNames(endpointPodNames("catalog"), green)
			}},
			{"les deux versions", func() bool {
				blue, bok := object("deployment", "catalog-blue")
				green, gok := object("deployment", "catalog-green")
				return bok && gok && workloadReady(blue, 2) && workloadReady(green, 2) &&
					text(templateContainer(blue, "nginx"), "image") == "nginx:1.26.3" &&
					text(templateContainer(green, "nginx"), "image") == "nginx:1.27.3"
			}},
		}
	}
	return nil
}

func checksFor() []check {
	switch {
	case strings.HasPrefix(exerciseID, "pod-"):
		return podChecks()
	case strings.HasPrefix(exerciseID, "rs-"):
		return replicaSetChecks()
	case strings.HasPrefix(exerciseID, "deploy-"):
		return deploymentChecks()
	case strings.HasPrefix(exerciseID, "ds-"):
		return daemonSetChecks()
	case strings.HasPrefix(exerciseID, "sts-"):
		return statefulSetChecks()
	case strings.HasPrefix(exerciseID, "vol-"):
		return volumeChecks()
	case strings.HasPrefix(exerciseID, "svc-"):
		return serviceChecks()
	}
	return nil
}

func validID(id string) bool {
	for _, prefixAndMax := range []struct {
		prefix string
		max    int
	}{{"pod-", 13}, {"rs-", 3}, {"deploy-", 8}, {"ds-", 4}, {"sts-", 5}, {"vol-", 8}, {"svc-", 12}} {
		if strings.HasPrefix(id, prefixAndMax.prefix) {
			n, err := strconv.Atoi(strings.TrimPrefix(id, prefixAndMax.prefix))
			return err == nil && n >= 1 && n <= prefixAndMax.max && len(strings.TrimPrefix(id, prefixAndMax.prefix)) == 2
		}
	}
	return false
}

func main() {
	if len(os.Args) != 3 || os.Args[1] != "check" || !validID(os.Args[2]) {
		fmt.Fprintln(os.Stderr, "Usage: ckad-check check <exercise-id>")
		os.Exit(2)
	}
	exerciseID = os.Args[2]
	namespace = "ckad-" + exerciseID

	if _, err := kubectl("get", "namespace", namespace, "--request-timeout=5s"); err != nil {
		fmt.Println("ÉCHEC — environnement de l'exercice indisponible")
		os.Exit(1)
	}

	checks := checksFor()
	if len(checks) == 0 {
		fmt.Println("ÉCHEC — exercice non pris en charge")
		os.Exit(2)
	}

	fmt.Printf("Validation de %s\n", exerciseID)
	failed := 0
	for _, item := range checks {
		passed := item.run()
		if passed {
			fmt.Printf("  OK  — %s\n", item.category)
		} else {
			fmt.Printf("  KO  — %s à revoir\n", item.category)
			failed++
		}
	}
	if failed > 0 {
		fmt.Printf("Résultat : %d catégorie(s) à revoir.\n", failed)
		os.Exit(1)
	}
	fmt.Println("Résultat : exercice réussi.")
}
