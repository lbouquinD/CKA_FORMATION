package main

import "strings"

func httpProbe(c M, field, path string, port, delay, period, failure int) bool {
	if c == nil || text(c, field, "httpGet", "path") != path || integer(c, field, "httpGet", "port") != port {
		return false
	}
	if delay >= 0 && integer(c, field, "initialDelaySeconds") != delay {
		return false
	}
	if period > 0 && integer(c, field, "periodSeconds") != period {
		return false
	}
	if failure > 0 && integer(c, field, "failureThreshold") != failure {
		return false
	}
	return true
}

func tcpProbe(c M, field string, port, period int) bool {
	return c != nil &&
		integer(c, field, "tcpSocket", "port") == port &&
		(period == 0 || integer(c, field, "periodSeconds") == period)
}

func execProbe(c M, field string, delay, period int, parts ...string) bool {
	if c == nil || integer(c, field, "initialDelaySeconds") != delay || integer(c, field, "periodSeconds") != period {
		return false
	}
	got := strings.Join(anyStrings(array(c, field, "exec", "command")), " ")
	if got == "" {
		return false
	}
	for _, part := range parts {
		if !strings.Contains(got, part) {
			return false
		}
	}
	return true
}

func restartCount(o M, name string) int {
	for _, raw := range array(o, "status", "containerStatuses") {
		item, _ := raw.(M)
		if text(item, "name") == name {
			return integer(item, "restartCount")
		}
	}
	return 99
}

func probeChecks() []check {
	switch exerciseID {
	case "probe-01":
		return []check{
			noted("readiness", "httpGet a besoin d'un chemin qui répond et du port écouté par le processus. Le port de la sonde est celui du conteneur, pas celui d'un Service.", func() bool {
				o, ok := object("pod", "web")
				c := container(o, "nginx")
				return ok && text(c, "image") == "nginx:1.27.3" && httpProbe(c, "readinessProbe", "/", 80, 2, 5, 0)
			}),
			noted("liveness", "Une liveness en échec redémarre le conteneur. Elle doit viser le même endpoint valide, avec son propre délai initial.", func() bool {
				o, ok := object("pod", "web")
				return ok && httpProbe(container(o, "nginx"), "livenessProbe", "/", 80, 5, 10, 0)
			}),
			noted("disponibilité", "Une readiness en échec laisse le Pod Running sans le passer Ready. Corrigez le chemin et le port, puis attendez la condition Ready.", func() bool {
				o, ok := object("pod", "web")
				return ok && podReady(o)
			}),
		}
	case "probe-02":
		return []check{
			noted("commande", "Le processus principal doit créer /tmp/healthy avant de dormir. Une sonde qui lit un fichier absent se termine avec un code différent de 0.", func() bool {
				o, ok := object("pod", "worker")
				c := container(o, "box")
				return ok && text(c, "image") == "busybox:1.36" && aliveCommand(c)
			}),
			noted("sondes exec", "Une sonde exec réussit quand sa commande se termine avec le code 0. initialDelaySeconds laisse le temps au fichier d'exister avant le premier essai.", func() bool {
				o, ok := object("pod", "worker")
				c := container(o, "box")
				return ok &&
					execProbe(c, "livenessProbe", 5, 10, "cat", "/tmp/healthy") &&
					execProbe(c, "readinessProbe", 5, 10, "cat", "/tmp/healthy")
			}),
			noted("disponibilité", "Si la sonde démarre avant le fichier, le kubelet redémarre le conteneur. Le fichier doit être là et le nombre de redémarrages doit rester bas.", func() bool {
				o, ok := object("pod", "worker")
				_, err := kubectl("exec", "-n", namespace, "worker", "-c", "box", "--", "test", "-f", "/tmp/healthy")
				return ok && podReady(o) && restartCount(o, "box") < 3 && err == nil
			}),
		}
	case "probe-03":
		return []check{
			noted("liveness", "tcpSocket vérifie qu'une connexion aboutit. Il n'a pas de chemin HTTP. Le port est celui où le processus écoute.", func() bool {
				o, ok := object("pod", "web")
				c := container(o, "nginx")
				return ok && text(c, "image") == "nginx:1.27.3" && tcpProbe(c, "livenessProbe", 80, 5)
			}),
			noted("readiness", "La readiness TCP utilise le même principe que la liveness : un port ouvert rend le Pod éligible au trafic.", func() bool {
				o, ok := object("pod", "web")
				return ok && tcpProbe(container(o, "nginx"), "readinessProbe", 80, 5)
			}),
			noted("disponibilité", "Un port où rien n'écoute fait échouer la sonde. nginx écoute sur 80 dans cette image.", func() bool {
				o, ok := object("pod", "web")
				return ok && podReady(o)
			}),
		}
	case "probe-04":
		return []check{
			noted("startup", "Tant que la startupProbe n'a pas réussi, liveness et readiness ne comptent pas. failureThreshold multiplié par periodSeconds donne le temps de démarrage accordé.", func() bool {
				o, ok := object("pod", "web")
				c := container(o, "nginx")
				return ok && text(c, "image") == "nginx:1.27.3" && httpProbe(c, "startupProbe", "/", 80, -1, 5, 12)
			}),
			noted("liveness", "La liveness reprend après le premier succès de la startup. Elle doit viser un chemin servi par le conteneur.", func() bool {
				o, ok := object("pod", "web")
				return ok && httpProbe(container(o, "nginx"), "livenessProbe", "/", 80, -1, 10, 0)
			}),
			noted("readiness", "La readiness attend aussi la fin de la startup, puis décide si le Pod reçoit du trafic.", func() bool {
				o, ok := object("pod", "web")
				return ok && httpProbe(container(o, "nginx"), "readinessProbe", "/", 80, -1, 5, 0)
			}),
			noted("disponibilité", "Les trois sondes coexistent. Le Pod devient Ready quand startup puis readiness ont réussi.", func() bool {
				o, ok := object("pod", "web")
				return ok && podReady(o)
			}),
		}
	case "probe-05":
		return []check{
			noted("identité", "Corrigez le template du Deployment shop. Le nom, l'image, le conteneur web, le label app=shop et les 2 réplicas restent.", func() bool {
				o, ok := object("deployment", "shop")
				c := templateContainer(o, "web")
				return ok && text(c, "image") == "nginx:1.27.3" && integer(o, "spec", "replicas") == 2 &&
					label(o, []string{"spec", "selector", "matchLabels"}, "app", "shop") &&
					label(o, []string{"spec", "template", "metadata", "labels"}, "app", "shop")
			}),
			noted("readiness", "Une sonde HTTP doit viser un chemin servi et le port réellement écouté. Un chemin inventé ou un mauvais port laisse les Pods hors service.", func() bool {
				o, ok := object("deployment", "shop")
				return ok && httpProbe(templateContainer(o, "web"), "readinessProbe", "/", 80, 3, 5, 0)
			}),
			noted("liveness", "Remplacez la sonde TCP qui vise un port fermé. Une liveness en échec redémarre le conteneur en boucle.", func() bool {
				o, ok := object("deployment", "shop")
				return ok && httpProbe(templateContainer(o, "web"), "livenessProbe", "/", 80, 5, 10, 0)
			}),
			noted("startup", "Ajoutez une startupProbe HTTP. Elle retarde les autres sondes le temps que le processus écoute. Les sondes se modifient dans le template, le rollout recrée les Pods.", func() bool {
				o, ok := object("deployment", "shop")
				return ok && httpProbe(templateContainer(o, "web"), "startupProbe", "/", 80, -1, 5, 6)
			}),
			noted("disponibilité", "Attendez la fin du rollout. Les événements du ReplicaSet montrent les sondes qui échouent encore.", func() bool {
				o, ok := object("deployment", "shop")
				return ok && rolloutComplete(o, 2)
			}),
		}
	}
	return nil
}
