# Corrections — Services

Fichier formateur. Ne pas ouvrir pendant la session stagiaire.

Les commandes ci-dessous sont des solutions types. D'autres formulations
équivalentes sont valides tant que l'état du cluster correspond aux critères.

---

## svc-01 — ClusterIP

```bash
kubectl create deployment web -n ckad-svc-01 --image=nginx:1.27.3 --replicas=2
kubectl label deployment web -n ckad-svc-01 app=web --overwrite
kubectl patch deployment web -n ckad-svc-01 --type=json -p '[
  {"op":"add","path":"/spec/template/spec/containers/0/ports","value":[{"containerPort":80}]},
  {"op":"replace","path":"/spec/template/spec/containers/0/name","value":"nginx"}
]'
kubectl expose deployment web -n ckad-svc-01 --name=web --port=80 --target-port=80
kubectl rollout status deployment/web -n ckad-svc-01
```

`kubectl create deployment` pose déjà `app=web` si le nom est `web`.
Vérifier le sélecteur avant d'exposer : `kubectl get deploy web -o wide`.

Contrôle : `kubectl get endpoints web -n ckad-svc-01` doit lister deux adresses.

---

## svc-02 — NodePort

Le Deployment `api` est fourni par `./lab.sh start svc-02`.

```bash
kubectl expose deployment api -n ckad-svc-02 --name=api-node \
  --type=NodePort --port=80 --target-port=80
kubectl patch service api-node -n ckad-svc-02 --type=json \
  -p '[{"op":"replace","path":"/spec/ports/0/nodePort","value":30080}]'
```

Ou en YAML, fixer `nodePort: 30080` dès la création. La plage par défaut est
`30000-32767`.

---

## svc-03 — Sélecteur

Le Service sélectionne `app=storefront`, les Pods portent `app=shop`.

```bash
kubectl set selector service/shop -n ckad-svc-03 app=shop
```

`kubectl set selector` remplace le sélecteur. Alternative :

```bash
kubectl patch service shop -n ckad-svc-03 -p '{"spec":{"selector":{"app":"shop"}}}'
```

Les Endpoints se remplissent sans recréer les Pods.

---

## svc-04 — Deux ports nommés

```bash
kubectl apply -n ckad-svc-04 -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: gateway
spec:
  type: ClusterIP
  selector:
    app: gateway
  ports:
    - name: http
      port: 80
      targetPort: 80
    - name: admin
      port: 8080
      targetPort: 80
EOF
```

Deux ports de Service peuvent cibler le même port de conteneur. Dès qu'il y
a plus d'un port, chacun doit avoir un `name`.

---

## svc-05 — targetPort nommé

Le conteneur déclare `ports.name: web`. Le Service doit reprendre ce nom.

```bash
kubectl apply -n ckad-svc-05 -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: named-web
spec:
  type: ClusterIP
  selector:
    app: named-web
  ports:
    - port: 80
      targetPort: web
EOF
```

`targetPort: 80` est refusé par le validateur : la valeur stockée doit être
la chaîne `web`.

---

## svc-06 — Sans sélecteur

Sans sélecteur, Kubernetes ne crée pas les Endpoints. Il faut une ressource
Endpoints de même nom.

```bash
kubectl apply -n ckad-svc-06 -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: legacy-db
spec:
  type: ClusterIP
  ports:
    - port: 5432
      targetPort: 5432
---
apiVersion: v1
kind: Endpoints
metadata:
  name: legacy-db
subsets:
  - addresses:
      - ip: 192.0.2.10
    ports:
      - port: 5432
EOF
```

`192.0.2.10` est une adresse de documentation (TEST-NET). Elle n'a pas
besoin d'être routable pour l'exercice.

Depuis Kubernetes 1.33, `kubectl apply` avertit que Endpoints v1 est
déprécié au profit d'EndpointSlice. Le validateur lit toujours l'objet
Endpoints : ne pas le remplacer.

---

## svc-07 — Headless

```bash
kubectl create deployment members -n ckad-svc-07 --image=busybox:1.36 \
  --replicas=2 --dry-run=client -o yaml > /tmp/svc-07.yaml
```

Éditer : conteneur `app`, commande `sleep 3600`, labels `app=members`.
Puis le Service :

```yaml
apiVersion: v1
kind: Service
metadata:
  name: members
spec:
  clusterIP: None
  selector:
    app: members
  ports:
    - port: 80
```

`clusterIP: None` publie directement les IP des Pods (DNS
`members-xxxx.members.ckad-svc-07.svc`). `kubectl get endpoints members`
doit montrer deux adresses.

---

## svc-08 — targetPort

Le Service pointe vers `9090`, nginx écoute sur `80`.

```bash
kubectl patch service payments -n ckad-svc-08 --type=json \
  -p '[{"op":"replace","path":"/spec/ports/0/targetPort","value":80}]'
```

Le sélecteur `app=payments` et le port `80` restent en place. Les Endpoints
passent de `9090` à `80`.

---

## svc-09 — LoadBalancer

```bash
kubectl expose deployment public -n ckad-svc-09 --name=public-lb \
  --type=LoadBalancer --port=80 --target-port=80
```

`EXTERNAL-IP` peut rester `<pending>` sans contrôleur (MetalLB, cloud, ou
ServiceLB k3s). Le type et les Endpoints suffisent.

---

## svc-10 — ClusterIP vers LoadBalancer

```bash
kubectl patch service edge -n ckad-svc-10 -p '{"spec":{"type":"LoadBalancer"}}'
```

Le `clusterIP` déjà attribué est conservé. Ne pas supprimer le Service.

---

## svc-11 — Canary

Le Service sélectionne seulement `app=catalog`. Chaque Deployment ajoute
`track` dans **son** sélecteur, sinon les deux contrôleurs se disputent les
Pods.

```yaml
# catalog-stable : replicas 3, image nginx:1.26.3
#   selector et template : app=catalog, track=stable
# catalog-canary : replicas 1, image nginx:1.27.3
#   selector et template : app=catalog, track=canary
# Service catalog :
#   selector : app=catalog
#   port 80 -> targetPort 80
```

`kubectl get endpoints catalog` doit lister 4 adresses.

---

## svc-12 — Blue-green

Les deux Deployments restent. Seul le sélecteur du Service change.

```bash
kubectl patch service catalog -n ckad-svc-12 \
  -p '{"spec":{"selector":{"app":"catalog","version":"green"}}}'
```

Avant : Endpoints = Pods `version=blue`. Après : uniquement `version=green`.
L'image verte est `nginx:1.27.3`, la bleue `nginx:1.26.3`.

