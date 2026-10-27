package main

import "encoding/json"

func clusterObject(kind, name string) (M, bool) {
	out, err := kubectl("get", kind, name, "-o", "json")
	if err != nil {
		return nil, false
	}
	var value M
	if json.Unmarshal(out, &value) != nil {
		return nil, false
	}
	return value, true
}

func findHTTPPath(o M, host, path string) M {
	for _, raw := range array(o, "spec", "rules") {
		rule, _ := raw.(M)
		if text(rule, "host") != host {
			continue
		}
		for _, rawPath := range array(rule, "http", "paths") {
			item, _ := rawPath.(M)
			if text(item, "path") == path {
				return item
			}
		}
	}
	return nil
}

func backendOK(path M, service string, port int) bool {
	return path != nil &&
		text(path, "pathType") == "Prefix" &&
		text(path, "backend", "service", "name") == service &&
		integer(path, "backend", "service", "port", "number") == port
}

func ingressClassOK(o M) bool {
	return text(o, "spec", "ingressClassName") == "ckad"
}

func hasTLS(o M, host, secret string) bool {
	for _, raw := range array(o, "spec", "tls") {
		item, _ := raw.(M)
		if text(item, "secretName") != secret {
			continue
		}
		for _, rawHost := range array(item, "hosts") {
			if fmtSprint(rawHost) == host {
				return true
			}
		}
	}
	return false
}

func ingressChecks() []check {
	switch exerciseID {
	case "ing-01":
		return []check{
			noted("classe", "ingressClassName relie l'Ingress au contrôleur. ./init.sh publie la classe ckad : sans elle, la ressource est ignorée.", func() bool {
				o, ok := object("ingress", "web")
				return ok && ingressClassOK(o)
			}),
			noted("règle", "L'hôte se place sur la règle, le chemin sur http.paths. pathType: Prefix est exigé pour ce parcours.", func() bool {
				o, ok := object("ingress", "web")
				return ok && backendOK(findHTTPPath(o, "web.ckad.local", "/"), "web", 80)
			}),
			noted("backend", "Le backend est un Service et un numéro de port, pas un Deployment ni un targetPort de Pod.", func() bool {
				o, ok := object("ingress", "web")
				svc, svcOK := object("service", "web")
				return ok && svcOK && integer(svc, "spec", "ports", "0", "port") == 80 &&
					backendOK(findHTTPPath(o, "web.ckad.local", "/"), "web", 80)
			}),
		}
	case "ing-02":
		return []check{
			noted("classe", "Posez ingressClassName: ckad, la classe installée par ./init.sh.", func() bool {
				o, ok := object("ingress", "shop")
				return ok && ingressClassOK(o)
			}),
			noted("chemin /", "Chaque chemin est une entrée de http.paths. / et /api ne sont pas interchangeables : le backend de / est le Service vitrine.", func() bool {
				o, ok := object("ingress", "shop")
				return ok && backendOK(findHTTPPath(o, "shop.ckad.local", "/"), "shop", 80)
			}),
			noted("chemin /api", "/api doit cibler le Service d'API, sur le port du Service. Un préfixe / ne remplace pas cette entrée.", func() bool {
				o, ok := object("ingress", "shop")
				return ok && backendOK(findHTTPPath(o, "shop.ckad.local", "/api"), "api", 80)
			}),
		}
	case "ing-03":
		return []check{
			noted("identité", "Conservez le nom, la classe ckad, l'hôte et le chemin /. Seul le backend est à corriger.", func() bool {
				o, ok := object("ingress", "app")
				path := findHTTPPath(o, "app.ckad.local", "/")
				return ok && ingressClassOK(o) && path != nil && text(path, "pathType") == "Prefix"
			}),
			noted("backend", "kubectl get svc montre le Service réel. Le port de l'Ingress est le port du Service, pas un port inventé dans le manifeste d'origine.", func() bool {
				o, ok := object("ingress", "app")
				_, svcOK := object("service", "web")
				return ok && svcOK && backendOK(findHTTPPath(o, "app.ckad.local", "/"), "web", 80)
			}),
		}
	case "ing-04":
		return []check{
			noted("classe", "Un seul Ingress, classe ckad, peut porter plusieurs hôtes dans spec.rules.", func() bool {
				o, ok := object("ingress", "colors")
				return ok && ingressClassOK(o)
			}),
			noted("hôte bleu", "Chaque hôte a sa propre entrée de rules. Le backend est le Service du même nom, port 80, chemin / en Prefix.", func() bool {
				o, ok := object("ingress", "colors")
				return ok && backendOK(findHTTPPath(o, "blue.ckad.local", "/"), "blue", 80)
			}),
			noted("hôte vert", "Le second hôte ne s'ajoute pas dans le même bloc host. Dupliquez une règle, pas seulement un chemin.", func() bool {
				o, ok := object("ingress", "colors")
				return ok && backendOK(findHTTPPath(o, "green.ckad.local", "/"), "green", 80)
			}),
		}
	case "ing-05":
		return []check{
			noted("secret", "Le Secret TLS du scénario doit rester de type kubernetes.io/tls. La section tls de l'Ingress le référence par son nom.", func() bool {
				o, ok := object("secret", "web-tls")
				return ok && text(o, "type") == "kubernetes.io/tls" && text(o, "data", "tls.crt") != "" && text(o, "data", "tls.key") != ""
			}),
			noted("tls", "spec.tls associe un hôte et un secretName. Cette section ne crée pas la route HTTP à elle seule.", func() bool {
				o, ok := object("ingress", "secure")
				return ok && ingressClassOK(o) && hasTLS(o, "secure.ckad.local", "web-tls")
			}),
			noted("règle HTTP", "Gardez une règle rules pour le même hôte, chemin / en Prefix, vers le Service web sur le port 80.", func() bool {
				o, ok := object("ingress", "secure")
				return ok && backendOK(findHTTPPath(o, "secure.ckad.local", "/"), "web", 80)
			}),
		}
	case "ing-06":
		return []check{
			noted("classe", "Sans ingressClassName, le contrôleur de ./init.sh ignore l'Ingress. La classe du parcours s'appelle ckad.", func() bool {
				o, ok := object("ingress", "web")
				return ok && ingressClassOK(o)
			}),
			noted("chemin", "Le chemin publié est /. pathType reste Prefix. Un chemin plus long ne répond pas à la racine de l'hôte.", func() bool {
				o, ok := object("ingress", "web")
				return ok && text(findHTTPPath(o, "repair.ckad.local", "/"), "path") == "/" &&
					text(findHTTPPath(o, "repair.ckad.local", "/"), "pathType") == "Prefix"
			}),
			noted("backend", "Le Service et son port étaient déjà bons. Ne les remplacez pas en corrigeant la classe et le chemin.", func() bool {
				o, ok := object("ingress", "web")
				return ok && backendOK(findHTTPPath(o, "repair.ckad.local", "/"), "web", 80)
			}),
		}
	}
	return nil
}
