# Corrections — NetworkPolicies

Fichier formateur. Ne pas ouvrir pendant la session stagiaire.

Le CNI de ce cluster (Flannel) n'applique pas les NetworkPolicies. Le
validateur contrôle l'objet. Un `curl` qui passe encore ne veut pas dire que
la politique est fausse.

`podSelector` choisit les Pods protégés. `from` / `to` choisissent les pairs.
`policyTypes` active chaque direction : sans `Egress`, le bloc `egress` est
ignoré.

---

## np-01 — Deny ingress

```bash
kubectl apply -n ckad-np-01 -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-ingress
spec:
  podSelector: {}
  policyTypes:
    - Ingress
EOF
```

`podSelector: {}` = tous les Pods. Pas de clé `ingress` = aucun flux entrant.

---

## np-02 — Client web vers api

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-allow
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: web
      ports:
        - protocol: TCP
          port: 80
```

---

## np-03 — Namespace clients

Le namespace `ckad-np-03-clients` porte déjà `role=clients`. Ne pas ajouter
de `podSelector` dans `from`.

```yaml
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              role: clients
      ports:
        - protocol: TCP
          port: 80
```

---

## np-04 — Egress vers db

```yaml
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
    - Egress
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: db
      ports:
        - protocol: TCP
          port: 5432
```

---

## np-05 — Mauvais podSelector

Le manifeste initial sélectionne `app=frontend`. Le remplacer par `app=web`.
La règle `from` / `app=client` / port `80` reste.

```bash
kubectl patch networkpolicy allow-web -n ckad-np-05 --type=merge \
  -p '{"spec":{"podSelector":{"matchLabels":{"app":"web"}}}}'
```

---

## np-06 — Les deux directions

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: locked-api
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: web
      ports:
        - protocol: TCP
          port: 80
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: db
      ports:
        - protocol: TCP
          port: 5432
```
