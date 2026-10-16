package main

func containerLimit(o M) M {
	for _, raw := range array(o, "spec", "limits") {
		item, _ := raw.(M)
		if text(item, "type") == "Container" {
			return item
		}
	}
	return nil
}

func hardCount(o M, key string, want int) bool {
	return integer(o, "spec", "hard", key) == want
}

func selectorApp(o M, value string) bool {
	return label(o, []string{"spec", "selector", "matchLabels"}, "app", value) &&
		label(o, []string{"spec", "template", "metadata", "labels"}, "app", value)
}

func podsQoS(selector, class string, count int) bool {
	items, ok := list("pods", selector)
	if !ok {
		return false
	}
	ready := 0
	for _, item := range items {
		if !podReady(item) {
			continue
		}
		if text(item, "status", "qosClass") != class {
			return false
		}
		ready++
	}
	return ready >= count
}

func resourceChecks() []check {
	switch exerciseID {
	case "res-01":
		return []check{
			noted("conteneur", "Le Pod api porte un conteneur nommé api. requests et limits se déclarent dans ce conteneur, sous resources.", func() bool {
				o, ok := object("pod", "api")
				c := container(o, "api")
				return ok && text(c, "image") == "nginx:1.27.3"
			}),
			noted("requests", "requests est le plancher utilisé par le scheduler. Le cpu s'écrit en millicores, la mémoire avec un suffixe binaire comme Mi.", func() bool {
				o, ok := object("pod", "api")
				c := container(o, "api")
				return ok && cpuEqual(text(c, "resources", "requests", "cpu"), "100m") &&
					memEqual(text(c, "resources", "requests", "memory"), "64Mi")
			}),
			noted("limits", "limits est le plafond du cgroup. Une limit inférieure à la request du même type est rejetée par l'API.", func() bool {
				o, ok := object("pod", "api")
				c := container(o, "api")
				return ok && cpuEqual(text(c, "resources", "limits", "cpu"), "200m") &&
					memEqual(text(c, "resources", "limits", "memory"), "128Mi")
			}),
			noted("disponibilité", "Un Pod dont les ressources sont acceptées démarre comme les autres. Attendez la condition Ready.", func() bool {
				o, ok := object("pod", "api")
				return ok && podReady(o)
			}),
		}
	case "res-02":
		return []check{
			noted("égalité", "La classe Guaranteed exige, sur chaque conteneur, une request égale à la limit pour le cpu et pour la mémoire. Les valeurs se posent dans le template.", func() bool {
				o, ok := object("deployment", "billing")
				c := templateContainer(o, "app")
				return ok && text(c, "image") == "nginx:1.27.3" && selectorApp(o, "billing") &&
					resourcesOK(c, "50m", "64Mi", "50m", "64Mi")
			}),
			noted("qos", "La classe QoS est calculée. Elle apparaît dans le statut du Pod. On ne l'écrit pas dans le manifeste.", func() bool {
				return podsQoS("app=billing", "Guaranteed", 2)
			}),
			noted("disponibilité", "Gardez 2 réplicas disponibles. Une request très haute peut laisser le Pod Pending si le nœud ne peut pas la satisfaire.", func() bool {
				o, ok := object("deployment", "billing")
				return ok && rolloutComplete(o, 2)
			}),
		}
	case "res-03":
		return []check{
			noted("bornes", "Le type Container du LimitRange porte min, max, default et defaultRequest. default remplit les limits, defaultRequest remplit les requests.", func() bool {
				o, ok := object("limitrange", "defaults")
				item := containerLimit(o)
				return ok && item != nil &&
					cpuEqual(text(item, "max", "cpu"), "500m") &&
					memEqual(text(item, "max", "memory"), "256Mi") &&
					cpuEqual(text(item, "min", "cpu"), "20m") &&
					memEqual(text(item, "min", "memory"), "32Mi") &&
					cpuEqual(text(item, "default", "cpu"), "200m") &&
					memEqual(text(item, "default", "memory"), "128Mi") &&
					cpuEqual(text(item, "defaultRequest", "cpu"), "50m") &&
					memEqual(text(item, "defaultRequest", "memory"), "64Mi")
			}),
			noted("valeurs par défaut", "Créez le LimitRange avant le Pod. Un Pod déjà présent n'est pas réécrit. Le conteneur créé sans resources reçoit alors default et defaultRequest.", func() bool {
				o, ok := object("pod", "plain")
				c := container(o, "web")
				return ok && text(c, "image") == "nginx:1.27.3" && resourcesOK(c, "50m", "64Mi", "200m", "128Mi")
			}),
			noted("disponibilité", "Le Pod plain doit démarrer avec les ressources injectées. Une valeur hors min ou max est refusée à la création.", func() bool {
				o, ok := object("pod", "plain")
				return ok && podReady(o)
			}),
		}
	case "res-04":
		return []check{
			noted("quota", "Une ResourceQuota additionne requests et limits de tous les conteneurs du namespace. kubectl describe resourcequota montre le plafond hard et le consommé used.", func() bool {
				o, ok := object("resourcequota", "team-quota")
				return ok && hardCount(o, "pods", 4) &&
					cpuEqual(text(o, "spec", "hard", "requests.cpu"), "500m") &&
					memEqual(text(o, "spec", "hard", "requests.memory"), "256Mi") &&
					cpuEqual(text(o, "spec", "hard", "limits.cpu"), "1") &&
					memEqual(text(o, "spec", "hard", "limits.memory"), "512Mi")
			}),
			noted("deployment", "Dès que la quota compte les requests, chaque conteneur doit en déclarer. Le produit réplicas × request doit rester sous le plafond.", func() bool {
				o, ok := object("deployment", "web")
				c := templateContainer(o, "nginx")
				return ok && integer(o, "spec", "replicas") == 2 && selectorApp(o, "web") &&
					text(c, "image") == "nginx:1.27.3" &&
					resourcesOK(c, "100m", "64Mi", "200m", "128Mi")
			}),
			noted("disponibilité", "Si la création est refusée, le ReplicaSet reste à 0 Pod et les événements citent la quota. Corrigez les nombres, puis attendez les réplicas disponibles.", func() bool {
				o, ok := object("deployment", "web")
				return ok && rolloutComplete(o, 2)
			}),
		}
	case "res-05":
		return []check{
			noted("quota conservée", "Ne modifiez pas team-quota. Décrivez-la pour lire les plafonds, puis ajustez le Deployment pour qu'il y tienne.", func() bool {
				o, ok := object("resourcequota", "team-quota")
				return ok && hardCount(o, "pods", 3) &&
					cpuEqual(text(o, "spec", "hard", "requests.cpu"), "200m") &&
					memEqual(text(o, "spec", "hard", "requests.memory"), "128Mi") &&
					cpuEqual(text(o, "spec", "hard", "limits.cpu"), "400m") &&
					memEqual(text(o, "spec", "hard", "limits.memory"), "256Mi")
			}),
			noted("dimensionnement", "Les Pods en attente dépassent un plafond. Baissez ce que chaque réplica demande et le nombre de réplicas. Retirer le bloc resources est aussi refusé : sans request, l'admission bloque.", func() bool {
				o, ok := object("deployment", "api")
				c := templateContainer(o, "api")
				return ok && integer(o, "spec", "replicas") == 2 && selectorApp(o, "api") &&
					text(c, "image") == "nginx:1.27.3" &&
					resourcesOK(c, "50m", "32Mi", "100m", "64Mi")
			}),
			noted("disponibilité", "Après la baisse, les anciens Pods refusés disparaissent au rollout. Attendez 2 réplicas à jour et disponibles.", func() bool {
				o, ok := object("deployment", "api")
				return ok && rolloutComplete(o, 2)
			}),
		}
	}
	return nil
}
