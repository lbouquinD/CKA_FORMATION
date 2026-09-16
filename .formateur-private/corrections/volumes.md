# Corrections — Volumes / PVC

Fichier formateur. Ne pas ouvrir pendant la session stagiaire.

Les commandes ci-dessous sont des solutions types. D'autres formulations
équivalentes sont valides tant que l'état du cluster correspond aux critères.

Les PVC de ce parcours utilisent la StorageClass `local-path` (provisioner
Rancher déjà présent sur k3s). Ne pas créer de PersistentVolume statique.

---

## vol-01 — emptyDir

```bash
kubectl run scratch-box -n ckad-vol-01 --image=busybox:1.36 \
  --labels=app=scratch --dry-run=client -o yaml > /tmp/vol-01.yaml
```

Éditer : nom du conteneur `box`, `command: ["sleep", "3600"]`, volume
`emptyDir` `scratch` monté sur `/scratch`. Puis :

```bash
kubectl apply -n ckad-vol-01 -f /tmp/vol-01.yaml
kubectl wait -n ckad-vol-01 --for=condition=Ready pod/scratch-box --timeout=60s
kubectl exec -n ckad-vol-01 scratch-box -c box -- \
  sh -c 'echo CKAD-VOL > /scratch/ready.txt'
```

`emptyDir` vit avec le Pod : recréer le Pod efface le fichier.

---

## vol-02 — emptyDir Memory

Même démarche que vol-01, Pod `ram-box`, volume `cache` :

```yaml
volumes:
  - name: cache
    emptyDir:
      medium: Memory
      sizeLimit: 32Mi
```

Montage `/cache`, fichier `/cache/ready.txt` avec `CKAD-RAM`.

`medium: Memory` place le volume en tmpfs. `sizeLimit` plafonne l'usage.

---

## vol-03 — emptyDir partagé (Deployment)

Deployment `share-html`, 1 réplica, sélecteur `app=share-html`.

- volume `emptyDir` nommé `html`;
- `loader` monte `/work` et écrit `index.html` puis `sleep 3600`;
- `web` (`nginx:1.27.3`) monte `/usr/share/nginx/html`.

```yaml
command: ["sh", "-c", "echo 'CKAD shared volume' > /work/index.html; sleep 3600"]
```

Le fichier doit être visible via `kubectl exec ... -c web -- cat /usr/share/nginx/html/index.html`.

---

## vol-04 — PVC + Pod

```bash
kubectl apply -n ckad-vol-04 -f - <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Mi
  storageClassName: local-path
---
apiVersion: v1
kind: Pod
metadata:
  name: app-storage
  labels:
    app: storage
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sleep", "3600"]
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: app-data
EOF
kubectl wait -n ckad-vol-04 --for=condition=Ready pod/app-storage --timeout=90s
```

`WaitForFirstConsumer` : le PVC passe `Bound` seulement après le scheduling
du Pod. Pas de PV à créer à la main.

---

## vol-05 — Persistance

PVC `keep-data` (`100Mi`, `local-path`, `ReadWriteOnce`) + Pod `keep-pod`
(même schéma que vol-04, montage `/data`).

```bash
kubectl exec -n ckad-vol-05 keep-pod -c app -- sh -c 'echo persisted > /data/marker'
kubectl delete pod keep-pod -n ckad-vol-05 --wait=true
# recréer le Pod identique, même claimName keep-data
kubectl wait -n ckad-vol-05 --for=condition=Ready pod/keep-pod --timeout=90s
kubectl exec -n ckad-vol-05 keep-pod -c app -- cat /data/marker
```

Le PVC survit à la suppression du Pod. Un `emptyDir` n'aurait pas conservé
le fichier.

---

## vol-06 — ConfigMap en volume

Le ConfigMap `app-config` est déjà là (`./lab.sh start vol-06`).

```yaml
volumes:
  - name: config
    configMap:
      name: app-config
# volumeMounts du conteneur reader :
#   - name: config
#     mountPath: /etc/app
```

Le fichier projeté est `/etc/app/app.conf` (`listen=8080`). Ne pas recréer
le ConfigMap ni copier le texte dans un `emptyDir`.

---

## vol-07 — PVC Pending

Le PVC `broken-data` pointe vers `missing-class`. `storageClassName` est
immuable : supprimer le Pod, puis le PVC, puis recréer les deux avec
`local-path`.

```bash
kubectl delete pod data-writer -n ckad-vol-07 --wait=true
kubectl delete pvc broken-data -n ckad-vol-07 --wait=true
kubectl apply -n ckad-vol-07 -f - <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: broken-data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
  storageClassName: local-path
---
apiVersion: v1
kind: Pod
metadata:
  name: data-writer
  labels:
    app: writer
spec:
  containers:
    - name: writer
      image: busybox:1.36
      command: ["sleep", "3600"]
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: broken-data
EOF
kubectl wait -n ckad-vol-07 --for=condition=Ready pod/data-writer --timeout=90s
kubectl exec -n ckad-vol-07 data-writer -c writer -- sh -c 'echo fixed > /data/ok'
```

---

## vol-08 — Deployment + PVC

PVC `web-content` (`50Mi`, `local-path`, `ReadWriteOnce`) puis Deployment
`static-web` **1 réplica** : un volume RWO ne peut pas être monté par
plusieurs Pods sur des nœuds différents.

```yaml
volumes:
  - name: content
    persistentVolumeClaim:
      claimName: web-content
# montage nginx : /usr/share/nginx/html
```

```bash
kubectl exec -n ckad-vol-08 deploy/static-web -c nginx -- \
  sh -c 'echo "CKAD pvc web" > /usr/share/nginx/html/index.html'
```

Le contenu nginx est souvent en lecture seule pour `nginx`. Si l'écriture
échoue, lancer un Pod éphémère qui monte le même PVC, ou `kubectl debug`.
Solution fiable : init container `busybox` qui écrit `index.html` avant le
démarrage de nginx, ou `kubectl exec` avec un conteneur ayant le PVC en
lecture-écriture. Le validateur lit le fichier dans le conteneur `nginx`.
