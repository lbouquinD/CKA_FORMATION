# Corrections — ReplicaSets, Deployments, DaemonSets, StatefulSets

Fichier formateur. Ne pas ouvrir pendant la session stagiaire.

Les commandes ci-dessous sont des solutions types. D'autres formulations
équivalentes sont valides tant que l'état du cluster correspond aux critères.
Point commun à tous ces contrôleurs : `spec.selector` est immuable en
`apps/v1`. Quand l'énoncé demande de changer le sélecteur, on supprime puis on
recrée la ressource avec le même nom.

---

## rs-01 — Créer un ReplicaSet

Pas de `kubectl create replicaset` : manifeste obligatoire.

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: frontend-rs
spec:
  replicas: 3
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
        - name: nginx
          image: nginx:1.27.3
```

```bash
kubectl apply -n ckad-rs-01 -f rs.yaml
kubectl get rs frontend-rs -n ckad-rs-01   # READY 3
```

Astuce : `kubectl create deployment ... --dry-run=client -o yaml`, puis changer
`kind` et supprimer `strategy`.

---

## rs-02 — Corriger un sélecteur hérité

Le sélecteur `app=legacy-api` est immuable : `kubectl edit` est refusé.

```bash
kubectl get rs api-rs -n ckad-rs-02 -o yaml > rs.yaml
# éditer : selector + labels du template -> app=api-v2, replicas 3,
# image nginx:1.27.3, retirer uid/resourceVersion/status
kubectl delete rs api-rs -n ckad-rs-02
kubectl apply -n ckad-rs-02 -f rs.yaml
```

Les anciens Pods (`app=legacy-api`) sont supprimés avec le ReplicaSet. Même
orphelins, ils ne seraient pas adoptés : leur label ne correspond plus.

---

## rs-03 — Scale et auto-réparation

```bash
kubectl scale rs worker-rs -n ckad-rs-03 --replicas=5
kubectl delete pod <un-des-pods-initiaux> -n ckad-rs-03
kubectl get pods -n ckad-rs-03 -l app=worker -w      # attendre le remplaçant
kubectl get pods -n ckad-rs-03 -l app=worker \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | sort > /tmp/ckad-rs-03.txt
```

Le validateur compare avec la liste des 2 Pods du départ (ConfigMap
`rs03-baseline`) : il faut supprimer un Pod **initial**, pas l'un des 3 ajoutés
par le scale. Écrire le fichier une fois le remplaçant créé.

---

## deploy-01 — Créer un Deployment

```bash
kubectl create deployment web -n ckad-deploy-01 \
  --image=nginx:1.27.3 --replicas=3 --port=80
kubectl rollout status deployment/web -n ckad-deploy-01
```

`kubectl create deployment` pose `app=web` sur le sélecteur et le template, et
nomme le conteneur d'après l'image : `nginx`.

---

## deploy-02 — Scale et inventaire

```bash
kubectl scale deployment catalog -n ckad-deploy-02 --replicas=5
kubectl rollout status deployment/catalog -n ckad-deploy-02
kubectl get deployment catalog -n ckad-deploy-02 --no-headers \
  | awk '{print $1, $2, $3, $4}' > /tmp/ckad-deploy-02.txt
```

Résultat attendu : `catalog 5/5 5 5`. `--no-headers` retire l'en-tête, `awk`
retire la colonne AGE.

---

## deploy-03 — Rolling update

```bash
kubectl set image deployment/storefront -n ckad-deploy-03 nginx=nginx:1.27.3
kubectl annotate deployment storefront -n ckad-deploy-03 \
  kubernetes.io/change-cause="upgrade to nginx 1.27.3" --overwrite
kubectl rollout status deployment/storefront -n ckad-deploy-03
kubectl rollout history deployment/storefront -n ckad-deploy-03
```

`--overwrite` est obligatoire : le setup a déjà posé `initial release`. Annoter
**après** `set image` : le contrôleur recopie `change-cause` sur le ReplicaSet
le plus récent. Annoter avant étiquetterait l'ancienne révision.

---

## deploy-04 — Revenir à une révision stable

```bash
kubectl rollout history deployment/payments -n ckad-deploy-04
# REVISION 1 initial release / 2 stable release / 3 failed release
kubectl rollout history deployment/payments -n ckad-deploy-04 --revision=2
kubectl rollout undo deployment/payments -n ckad-deploy-04 --to-revision=2
kubectl rollout status deployment/payments -n ckad-deploy-04
```

Un simple `rollout undo` reviendrait aussi à la révision 2 ici, mais
`--to-revision` est la réponse attendue. La révision 2 est renumérotée 4 :
l'historique reste consultable. Image finale : `nginx:1.27.3`.

---

## deploy-05 — Stratégie de disponibilité

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: critical-api
spec:
  replicas: 4
  revisionHistoryLimit: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
  selector:
    matchLabels:
      app: critical-api
  template:
    metadata:
      labels:
        app: critical-api
    spec:
      containers:
        - name: api
          image: nginx:1.27.3
```

`maxUnavailable: 0` + `maxSurge: 1` : un Pod neuf doit être Ready avant
qu'un ancien ne soit arrêté.

---

## deploy-06 — Diagnostic croisé

Quatre causes : image inexistante, `command` qui sort en erreur, probe sur
`/healthz:8080`, limites trop basses (16Mi).

```yaml
spec:
  template:
    spec:
      containers:
        - name: api
          image: nginx:1.27.3
          # plus de champ command
          readinessProbe:
            httpGet:
              path: /
              port: 80
          resources:
            limits:
              cpu: 200m
              memory: 128Mi
```

```bash
kubectl edit deployment broken-api -n ckad-deploy-06
kubectl rollout status deployment/broken-api -n ckad-deploy-06
```

Supprimer la ligne `command` dans `kubectl edit`. Un `kubectl set image` seul ne
suffit pas : le Pod démarre puis sort aussitôt.

---

## deploy-07 — Sélecteur immuable

```bash
kubectl get deployment orders -n ckad-deploy-07 -o yaml > orders.yaml
# éditer : selector + labels du template -> app=orders, image nginx:1.27.3
kubectl delete deployment orders -n ckad-deploy-07
kubectl apply -n ckad-deploy-07 -f orders.yaml
kubectl rollout status deployment/orders -n ckad-deploy-07
```

`kubectl apply` sur le sélecteur modifié renvoie `field is immutable`.
`kubectl replace --force` fait la suppression et la recréation en une commande.

---

## deploy-08 — Déploiement canary

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-stable
spec:
  replicas: 4
  selector:
    matchLabels:
      app: frontend
      track: stable
  template:
    metadata:
      labels:
        app: frontend
        track: stable
    spec:
      containers:
        - name: nginx
          image: nginx:1.26.3
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-canary
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
      track: canary
  template:
    metadata:
      labels:
        app: frontend
        track: canary
    spec:
      containers:
        - name: nginx
          image: nginx:1.27.3
```

```bash
kubectl get deployments -n ckad-deploy-08 -o name | cut -d/ -f2 | sort > /tmp/ckad-deploy-08.txt
```

Chaque sélecteur inclut `track` : sinon les deux Deployments se disputent les
mêmes Pods. Un Service sur `app=frontend` seul répartit ensuite 4/1.

---

## ds-01 — Agent sur chaque nœud

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-agent
spec:
  selector:
    matchLabels:
      app: node-agent
  template:
    metadata:
      labels:
        app: node-agent
    spec:
      containers:
        - name: agent
          image: busybox:1.36
          command: ["sh", "-c", "sleep 3600"]
```

Pas de `kubectl create daemonset` : partir d'un Deployment en dry-run, changer
`kind`, retirer `replicas` et `strategy`.

---

## ds-02 — Ciblage des nœuds Linux

Même squelette que ds-01, avec dans le template :

```yaml
    spec:
      nodeSelector:
        kubernetes.io/os: linux
      containers:
        - name: collector
          image: busybox:1.36
          command: ["sh", "-c", "sleep 3600"]
```

Le `nodeSelector` va dans `spec.template.spec`, pas dans `spec` du DaemonSet.

---

## ds-03 — Tolérer un nœud dédié

```bash
kubectl patch daemonset log-agent -n ckad-ds-03 --type=json -p '[
  {"op":"add","path":"/spec/template/spec/tolerations","value":[
    {"key":"dedicated","operator":"Equal","value":"observability","effect":"NoSchedule"}]}]'
kubectl rollout status daemonset/log-agent -n ckad-ds-03
```

Ou `kubectl edit`. Aucun nœud n'est tainté : la tolérance autorise, elle
n'impose rien.

---

## ds-04 — Mise à jour OnDelete

```bash
kubectl patch daemonset manual-agent -n ckad-ds-04 --type=merge \
  -p '{"spec":{"updateStrategy":{"type":"OnDelete","rollingUpdate":null}}}'
kubectl set image daemonset/manual-agent -n ckad-ds-04 agent=busybox:1.36
kubectl delete pod -n ckad-ds-04 -l app=manual-agent
kubectl get pods -n ckad-ds-04 -l app=manual-agent -w    # attendre le nouveau Pod Ready
kubectl get pods -n ckad-ds-04 -l app=manual-agent \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | sort > /tmp/ckad-ds-04.txt
```

Changer la stratégie **avant** l'image : sinon le RollingUpdate remplace déjà les
Pods. `kubectl rollout status` ne fonctionne pas en OnDelete. Écrire le fichier
après remplacement : les noms changent.

---

## sts-01 — Identité réseau stable

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-headless
spec:
  clusterIP: None
  selector:
    app: stateful-web
  ports:
    - port: 80
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: stateful-web
spec:
  serviceName: web-headless
  replicas: 3
  selector:
    matchLabels:
      app: stateful-web
  template:
    metadata:
      labels:
        app: stateful-web
    spec:
      containers:
        - name: nginx
          image: nginx:1.27.3
          ports:
            - containerPort: 80
```

Les Pods sont créés dans l'ordre 0, 1, 2. DNS :
`stateful-web-0.web-headless.ckad-sts-01.svc.cluster.local`.

---

## sts-02 — Initialisation ordonnée

```yaml
apiVersion: v1
kind: Service
metadata:
  name: db-headless
spec:
  clusterIP: None
  selector:
    app: db
  ports:
    - port: 80
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: db
spec:
  serviceName: db-headless
  replicas: 3
  podManagementPolicy: OrderedReady
  selector:
    matchLabels:
      app: db
  template:
    metadata:
      labels:
        app: db
    spec:
      volumes:
        - name: data
          emptyDir: {}
      initContainers:
        - name: identity
          image: busybox:1.36
          command: ["sh", "-c", "hostname > /data/identity"]
          volumeMounts:
            - name: data
              mountPath: /data
      containers:
        - name: database
          image: busybox:1.36
          command: ["sleep", "3600"]
          volumeMounts:
            - name: data
              mountPath: /data
```

Le validateur exige exactement `command: ["sleep", "3600"]` pour `database`.
Vérification : `kubectl exec db-1 -n ckad-sts-02 -- cat /data/identity`.

---

## sts-03 — Stockage persistant

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: cache
spec:
  serviceName: cache-headless
  replicas: 2
  selector:
    matchLabels:
      app: cache
  template:
    metadata:
      labels:
        app: cache
    spec:
      containers:
        - name: cache
          image: busybox:1.36
          command: ["sleep", "3600"]
          volumeMounts:
            - name: data
              mountPath: /data
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: local-path
        resources:
          requests:
            storage: 100Mi
```

Plus le Service headless `cache-headless` (`clusterIP: None`, `app=cache`).

```bash
kubectl exec cache-0 -n ckad-sts-03 -- sh -c 'echo ok > /data/marker'
kubectl delete pod cache-0 -n ckad-sts-03
kubectl wait --for=condition=Ready pod/cache-0 -n ckad-sts-03 --timeout=90s
kubectl exec cache-0 -n ckad-sts-03 -- cat /data/marker
```

Le PVC `data-cache-0` survit au Pod et est remonté sur le nouveau `cache-0`.
La suppression prend ~30 s : `sleep` ignore SIGTERM.

---

## sts-04 — Mise à jour partitionnée

```bash
kubectl patch statefulset rolling-db -n ckad-sts-04 --type=merge -p '{"spec":{
  "replicas":4,
  "updateStrategy":{"type":"RollingUpdate","rollingUpdate":{"partition":2}},
  "template":{"spec":{"containers":[{"name":"db","image":"nginx:1.27.3"}]}}}}'
kubectl rollout status statefulset/rolling-db -n ckad-sts-04
kubectl get pods -n ckad-sts-04 -l app=rolling-db \
  -o custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[0].image
```

La partition doit être en place **avant** le changement d'image (même patch, ou
patch séparé d'abord). Seuls les ordinaux `>= 2` passent en 1.27.3 ;
`rolling-db-3`, créé par le scale, naît directement avec la nouvelle révision.

---

## sts-05 — Réparer puis supprimer proprement

`serviceName` et `selector` sont immuables : recréer.

```bash
kubectl delete statefulset sessions -n ckad-sts-05   # cascade : libère sessions-0/1
```

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: sessions
spec:
  serviceName: sessions-headless
  replicas: 2
  selector:
    matchLabels:
      app: sessions
  template:
    metadata:
      labels:
        app: sessions
    spec:
      containers:
        - name: sessions
          image: nginx:1.27.3
```

```bash
kubectl rollout status statefulset/sessions -n ckad-sts-05
kubectl get pods -n ckad-sts-05 -l app=sessions \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | sort > /tmp/ckad-sts-05.txt
kubectl delete statefulset sessions -n ckad-sts-05 --cascade=orphan
```

La première suppression doit être en cascade : des Pods orphelins
`sessions-0/1` (label `legacy-sessions`) bloqueraient la création des nouveaux
Pods de même nom. La seconde est `--cascade=orphan` : les Pods restent, sans
`ownerReferences`.
