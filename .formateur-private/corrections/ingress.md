# Corrections — Ingress

Fichier formateur. Ne pas ouvrir pendant la session stagiaire.

`./init.sh` installe ingress-nginx et l'IngressClass `ckad`. Tous les
Ingress du parcours portent `ingressClassName: ckad`.

Le backend est toujours un Service (`spec.rules[].http.paths[].backend.service`),
avec `pathType: Prefix`.

---

## ing-01 — Un hôte

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web
spec:
  ingressClassName: ckad
  rules:
    - host: web.ckad.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web
                port:
                  number: 80
```

---

## ing-02 — Deux chemins

Même schéma, Ingress `shop`, hôte `shop.ckad.local` :

- path `/` → service `shop` port `80`
- path `/api` → service `api` port `80`

Les deux entrées sont dans `http.paths` de la même règle.

---

## ing-03 — Backend

```bash
kubectl patch ingress app -n ckad-ing-03 --type=json -p '[
  {"op":"replace","path":"/spec/rules/0/http/paths/0/backend/service/name","value":"web"},
  {"op":"replace","path":"/spec/rules/0/http/paths/0/backend/service/port/number","value":80}
]'
```

La classe, l'hôte `app.ckad.local` et le chemin `/` ne bougent pas.

---

## ing-04 — Deux hôtes

Ingress `colors`, classe `ckad`, deux éléments dans `spec.rules` :

- host `blue.ckad.local` → service `blue:80`, path `/`
- host `green.ckad.local` → service `green:80`, path `/`

---

## ing-05 — TLS

Le Secret `web-tls` est créé par `setups/ing-05.sh`. Ne pas le régénérer.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: secure
spec:
  ingressClassName: ckad
  tls:
    - hosts:
        - secure.ckad.local
      secretName: web-tls
  rules:
    - host: secure.ckad.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web
                port:
                  number: 80
```

---

## ing-06 — Classe et chemin

L'Ingress existe déjà, sans classe, avec le chemin `/old` et l'hôte
`repair.ckad.local`.

```bash
kubectl patch ingress web -n ckad-ing-06 --type=json -p '[
  {"op":"add","path":"/spec/ingressClassName","value":"ckad"},
  {"op":"replace","path":"/spec/rules/0/http/paths/0/path","value":"/"}
]'
```

Si `ingressClassName` est absent, `add` convient. S'il est vide, utiliser
`replace`. Le backend `web:80` et l'hôte `repair.ckad.local` restent.
