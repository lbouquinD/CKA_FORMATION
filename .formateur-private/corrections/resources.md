# Corrections — Requests et limits

Fichier formateur. Ne pas ouvrir pendant la session stagiaire.

`requests` sert au scheduler. `limits` est le plafond du cgroup. QoS :

- `Guaranteed` : pour chaque conteneur, request cpu = limit cpu et request
  mémoire = limit mémoire ;
- `Burstable` : au moins une request ou une limit, sans l'égalité complète ;
- `BestEffort` : rien du tout.

Si on pose une limit sans request, Kubernetes recopie la limit dans la
request. Le Pod devient alors `Guaranteed`.

Un LimitRange agit à l'admission des prochains Pods. Une ResourceQuota additionne
le namespace. `kubectl describe resourcequota` et `kubectl describe rs` montrent
un refus `exceeded quota`.

---

## res-01 — Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: api
spec:
  containers:
    - name: api
      image: nginx:1.27.3
      resources:
        requests:
          cpu: 100m
          memory: 64Mi
        limits:
          cpu: 200m
          memory: 128Mi
```

---

## res-02 — Guaranteed

Deployment `billing`, sélecteur et label `app=billing`, 2 réplicas, conteneur
`app`, image `nginx:1.27.3` :

```yaml
resources:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    cpu: 50m
    memory: 64Mi
```

Contrôle : `kubectl get pods -n ckad-res-02 -o custom-columns=NAME:.metadata.name,QOS:.status.qosClass`.

---

## res-03 — LimitRange

Créer le LimitRange **avant** le Pod.

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: defaults
spec:
  limits:
    - type: Container
      max:
        cpu: 500m
        memory: 256Mi
      min:
        cpu: 20m
        memory: 32Mi
      default:
        cpu: 200m
        memory: 128Mi
      defaultRequest:
        cpu: 50m
        memory: 64Mi
```

Puis un Pod `plain` / conteneur `web` / `nginx:1.27.3` sans `resources`.
`kubectl get pod plain -o yaml` montre les valeurs injectées.

---

## res-04 — ResourceQuota

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-quota
spec:
  hard:
    pods: "4"
    requests.cpu: 500m
    requests.memory: 256Mi
    limits.cpu: "1"
    limits.memory: 512Mi
```

Deployment `web`, 2 réplicas, label `app=web`, conteneur `nginx` :
requests `100m` / `64Mi`, limits `200m` / `128Mi`.

Consommation : 200m / 128Mi de requests, 400m / 256Mi de limits, 2 Pods.
Tout tient sous les plafonds.

---

## res-05 — Quota déjà dépassée

Plafonds laissés tels quels : 3 Pods, requests `200m` / `128Mi`, limits
`400m` / `256Mi`.

Le setup demande 3 réplicas à `200m` / `200Mi` de requests. La mémoire dépasse
déjà le plafond à elle seule, donc aucun Pod n'est admis. Réduire seulement
le nombre de réplicas ne suffit pas.

Cible : 2 réplicas, requests `50m` / `32Mi`, limits `100m` / `64Mi`.

```bash
kubectl set resources deployment api -n ckad-res-05 -c api \
  --requests=cpu=50m,memory=32Mi --limits=cpu=100m,memory=64Mi
kubectl scale deployment api -n ckad-res-05 --replicas=2
kubectl rollout status deployment/api -n ckad-res-05
```

Total : requests `100m` / `64Mi`, limits `200m` / `128Mi`, 2 Pods.
