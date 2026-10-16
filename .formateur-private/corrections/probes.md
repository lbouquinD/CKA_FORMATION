# Corrections — Sondes

Fichier formateur. Ne pas ouvrir pendant la session stagiaire.

Une sonde réussit sur un code HTTP 2xx-3xx, une connexion TCP établie, ou une
commande qui se termine à 0. La liveness redémarre le conteneur. La readiness
retire le Pod des endpoints. La startup bloque les deux autres jusqu'à son
premier succès.

Les sondes d'un Pod sont immuables : on supprime et on recrée. Celles d'un
Deployment se corrigent dans le template, et le rollout remplace les Pods.

---

## probe-01 — HTTP

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web
spec:
  containers:
    - name: nginx
      image: nginx:1.27.3
      readinessProbe:
        httpGet:
          path: /
          port: 80
        initialDelaySeconds: 2
        periodSeconds: 5
      livenessProbe:
        httpGet:
          path: /
          port: 80
        initialDelaySeconds: 5
        periodSeconds: 10
```

---

## probe-02 — exec

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: worker
spec:
  containers:
    - name: box
      image: busybox:1.36
      command: ["sh", "-c", "touch /tmp/healthy && sleep 3600"]
      readinessProbe:
        exec:
          command: ["cat", "/tmp/healthy"]
        initialDelaySeconds: 5
        periodSeconds: 10
      livenessProbe:
        exec:
          command: ["cat", "/tmp/healthy"]
        initialDelaySeconds: 5
        periodSeconds: 10
```

Le `touch` est avant le `sleep`. Sans `initialDelaySeconds`, la première
sonde peut partir avant le fichier et faire redémarrer le conteneur.

---

## probe-03 — TCP

Même Pod nginx que probe-01, avec :

```yaml
livenessProbe:
  tcpSocket:
    port: 80
  periodSeconds: 5
readinessProbe:
  tcpSocket:
    port: 80
  periodSeconds: 5
```

---

## probe-04 — startup

```yaml
startupProbe:
  httpGet:
    path: /
    port: 80
  periodSeconds: 5
  failureThreshold: 12
livenessProbe:
  httpGet:
    path: /
    port: 80
  periodSeconds: 10
readinessProbe:
  httpGet:
    path: /
    port: 80
  periodSeconds: 5
```

12 × 5 s = 60 s de grâce. nginx démarre plus vite : le Pod passe Ready dès
le premier succès.

---

## probe-05 — Réparation

Le setup vise `/healthz:8080` et un `tcpSocket` sur le port 9. nginx écoute
sur 80 et sert `/`.

```bash
kubectl edit deployment shop -n ckad-probe-05
kubectl rollout status deployment/shop -n ckad-probe-05
```

Dans le template, remplacer les deux sondes et ajouter :

```yaml
startupProbe:
  httpGet:
    path: /
    port: 80
  periodSeconds: 5
  failureThreshold: 6
readinessProbe:
  httpGet:
    path: /
    port: 80
  initialDelaySeconds: 3
  periodSeconds: 5
livenessProbe:
  httpGet:
    path: /
    port: 80
  initialDelaySeconds: 5
  periodSeconds: 10
```
