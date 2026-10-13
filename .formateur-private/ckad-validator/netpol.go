package main

func selectsAllPods(o M) bool {
	selector, ok := at(o, "spec", "podSelector").(M)
	if !ok {
		return false
	}
	if len(selector) == 0 {
		return true
	}
	if len(selector) != 1 {
		return false
	}
	labels, exists := selector["matchLabels"]
	if !exists {
		return false
	}
	if labels == nil {
		return true
	}
	parsed, ok := labels.(M)
	return ok && len(parsed) == 0
}

func protectsPods(o M, key, value string) bool {
	return text(o, "spec", "podSelector", "matchLabels", key) == value
}

func hasPolicyType(o M, want string) bool {
	for _, raw := range array(o, "spec", "policyTypes") {
		if fmtSprint(raw) == want {
			return true
		}
	}
	return false
}

func fmtSprint(value any) string {
	if value == nil {
		return ""
	}
	return text(M{"v": value}, "v")
}

func rulesOf(o M, field string) []M {
	var result []M
	for _, raw := range array(o, "spec", field) {
		item, _ := raw.(M)
		if item != nil {
			result = append(result, item)
		}
	}
	return result
}

func ruleHasPort(rule M, port int, protocol string) bool {
	for _, raw := range array(rule, "ports") {
		item, _ := raw.(M)
		got := text(item, "protocol")
		if integer(item, "port") == port && (got == "" || got == protocol) {
			return true
		}
	}
	return false
}

func hasPodPeer(o M, direction, peerField, key, value string) bool {
	for _, rule := range rulesOf(o, direction) {
		for _, raw := range array(rule, peerField) {
			peer, _ := raw.(M)
			if at(peer, "namespaceSelector") != nil {
				continue
			}
			if text(peer, "podSelector", "matchLabels", key) == value {
				return true
			}
		}
	}
	return false
}

func allowsPod(o M, direction, peerField, key, value string, port int) bool {
	for _, rule := range rulesOf(o, direction) {
		matched := false
		for _, raw := range array(rule, peerField) {
			peer, _ := raw.(M)
			if at(peer, "namespaceSelector") != nil {
				continue
			}
			if text(peer, "podSelector", "matchLabels", key) == value {
				matched = true
			}
		}
		if matched && ruleHasPort(rule, port, "TCP") {
			return true
		}
	}
	return false
}

func allowsNamespace(o M, key, value string, port int) bool {
	for _, rule := range rulesOf(o, "ingress") {
		matched := false
		for _, raw := range array(rule, "from") {
			peer, _ := raw.(M)
			if at(peer, "podSelector") != nil {
				continue
			}
			if text(peer, "namespaceSelector", "matchLabels", key) == value {
				matched = true
			}
		}
		if matched && ruleHasPort(rule, port, "TCP") {
			return true
		}
	}
	return false
}

func networkPolicyChecks() []check {
	switch exerciseID {
	case "np-01":
		return []check{
			noted("politique", "La ressource attendue est une NetworkPolicy. kubectl explain networkpolicy.spec rappelle les trois champs qui comptent : podSelector, policyTypes et ingress.", func() bool {
				o, ok := object("networkpolicy", "deny-ingress")
				return ok && text(o, "metadata", "namespace") == namespace
			}),
			noted("cible", "Un podSelector: {} sélectionne tous les Pods du namespace. S'il vise un label, la politique ne couvre pas l'ensemble du namespace.", func() bool {
				o, ok := object("networkpolicy", "deny-ingress")
				return ok && selectsAllPods(o)
			}),
			noted("isolation", "policyTypes doit citer Ingress. Une entrée ingress vide ({}) autorise tout le monde : pour tout refuser, omettez les règles ou laissez la liste vide.", func() bool {
				o, ok := object("networkpolicy", "deny-ingress")
				return ok && hasPolicyType(o, "Ingress") && len(array(o, "spec", "ingress")) == 0
			}),
		}
	case "np-02":
		return []check{
			noted("pods protégés", "podSelector désigne les Pods qui subissent la politique. Les clients autorisés ne se mettent pas à cet endroit.", func() bool {
				o, ok := object("networkpolicy", "api-allow")
				return ok && protectsPods(o, "app", "api") && hasPolicyType(o, "Ingress")
			}),
			noted("source", "ingress.from.podSelector filtre les Pods sources du même namespace. Un namespaceSelector dans le même élément from se combine en ET et rétrécit la règle.", func() bool {
				o, ok := object("networkpolicy", "api-allow")
				return ok && hasPodPeer(o, "ingress", "from", "app", "web")
			}),
			noted("port", "Le port de la règle est celui du Pod cible. Le protocole non précisé vaut TCP, mais le numéro doit être explicite.", func() bool {
				o, ok := object("networkpolicy", "api-allow")
				return ok && allowsPod(o, "ingress", "from", "app", "web", 80)
			}),
		}
	case "np-03":
		return []check{
			noted("namespace source", "Le namespace des clients doit rester labellisé. Un namespaceSelector lit les labels du Namespace, pas ceux des Pods.", func() bool {
				o, ok := clusterObject("namespace", "ckad-np-03-clients")
				return ok && text(o, "metadata", "labels", "role") == "clients"
			}),
			noted("pods protégés", "La politique protège l'API de ce namespace. Le podSelector ne décrit pas le namespace distant.", func() bool {
				o, ok := object("networkpolicy", "allow-clients")
				return ok && protectsPods(o, "app", "api") && hasPolicyType(o, "Ingress")
			}),
			noted("règle", "Pour viser tout un namespace, from ne contient qu'un namespaceSelector. Ajouter un podSelector dans le même élément exige aussi un label de Pod.", func() bool {
				o, ok := object("networkpolicy", "allow-clients")
				return ok && allowsNamespace(o, "role", "clients", 80)
			}),
		}
	case "np-04":
		return []check{
			noted("pods protégés", "La politique s'applique aux Pods qui ouvrent la connexion, pas aux Pods de destination.", func() bool {
				o, ok := object("networkpolicy", "api-egress")
				return ok && protectsPods(o, "app", "api")
			}),
			noted("policyTypes", "Un bloc egress est ignoré tant que policyTypes ne contient pas Egress. Ingress et Egress sont indépendants.", func() bool {
				o, ok := object("networkpolicy", "api-egress")
				return ok && hasPolicyType(o, "Egress")
			}),
			noted("destination", "egress.to.podSelector désigne la cible dans le même namespace. Le port est celui du Pod de destination.", func() bool {
				o, ok := object("networkpolicy", "api-egress")
				return ok && allowsPod(o, "egress", "to", "app", "db", 5432)
			}),
		}
	case "np-05":
		return []check{
			noted("cible", "Comparez podSelector aux labels des Pods à protéger. Le sélecteur d'origine ne correspond à aucun Pod du namespace.", func() bool {
				o, ok := object("networkpolicy", "allow-web")
				return ok && protectsPods(o, "app", "web") && hasPolicyType(o, "Ingress")
			}),
			noted("source conservée", "Seule la cible était fausse. La règle from doit continuer à citer les Pods clients, sur le port du serveur.", func() bool {
				o, ok := object("networkpolicy", "allow-web")
				return ok && allowsPod(o, "ingress", "from", "app", "client", 80)
			}),
			noted("pods présents", "Les Pods du scénario doivent rester en place. Corrigez la politique, pas les workloads.", func() bool {
				_, web := object("pod", "web")
				_, client := object("pod", "client")
				return web && client
			}),
		}
	case "np-06":
		return []check{
			noted("policyTypes", "Citez Ingress et Egress. Une direction absente de policyTypes n'applique pas le bloc du même nom.", func() bool {
				o, ok := object("networkpolicy", "locked-api")
				return ok && protectsPods(o, "app", "api") && hasPolicyType(o, "Ingress") && hasPolicyType(o, "Egress")
			}),
			noted("entrée", "L'entrée autorisée se déclare sous ingress.from, vers les Pods protégés, sur leur port d'écoute.", func() bool {
				o, ok := object("networkpolicy", "locked-api")
				return ok && allowsPod(o, "ingress", "from", "app", "web", 80)
			}),
			noted("sortie", "La sortie se déclare sous egress.to. Elle vise les Pods de destination et le port sur lequel ils écoutent.", func() bool {
				o, ok := object("networkpolicy", "locked-api")
				return ok && allowsPod(o, "egress", "to", "app", "db", 5432)
			}),
		}
	}
	return nil
}
