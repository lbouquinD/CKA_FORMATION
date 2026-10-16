# Corrections — Secrets

Fichier formateur. Ne pas ouvrir pendant la session stagiaire.

`data` est du base64, pas du chiffrement. `stringData` est converti en `data`
à l'enregistrement. Un Secret TLS a le type `kubernetes.io/tls` et les clés
imposées `tls.crt` et `tls.key`.

---

## sec-01 — Opaque

```bash
kubectl create secret generic db-creds -n ckad-sec-01 \
  --from-literal=username=dbadmin \
  --from-literal=password='Ck4d-db-91'
```

Vérification : `kubectl get secret db-creds -n ckad-sec-01 -o jsonpath='{.data.password}' | base64 -d`.

---

## sec-02 — Fichiers

`./lab.sh start sec-02` écrit `/tmp/ckad-sec-02/username` et `password`.

```bash
kubectl create secret generic file-creds -n ckad-sec-02 \
  --from-file=username=/tmp/ckad-sec-02/username \
  --from-file=password=/tmp/ckad-sec-02/password
```

Le nom de la clé est le nom du fichier. `--from-file=/tmp/ckad-sec-02` monterait
tout le répertoire, avec les mêmes noms.

---

## sec-03 — Variables

Le Secret `api-token` a les clés `user` et `token`. `kubectl run` ne pose pas
un `secretKeyRef` : passer par un manifeste.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: client
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sleep", "3600"]
      env:
        - name: API_USER
          valueFrom:
            secretKeyRef:
              name: api-token
              key: user
        - name: API_TOKEN
          valueFrom:
            secretKeyRef:
              name: api-token
              key: token
```

`envFrom.secretRef` aurait créé les variables `user` et `token`, pas
`API_USER` et `API_TOKEN`.

---

## sec-04 — Projection

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: config-reader
spec:
  containers:
    - name: box
      image: busybox:1.36
      command: ["sleep", "3600"]
      volumeMounts:
        - name: settings
          mountPath: /etc/settings
          readOnly: true
  volumes:
    - name: settings
      secret:
        secretName: app-config
        defaultMode: 0400
        items:
          - key: config.properties
            path: config.properties
          - key: token
            path: token
```

`0400` est lu en octal (256). Écrire `400` donne un autre mode et le contrôle
échoue. Sans `items`, `note` apparaît aussi dans le répertoire.

---

## sec-05 — TLS

```bash
kubectl create secret tls shop-tls -n ckad-sec-05 \
  --cert=/tmp/ckad-sec-05/tls.crt \
  --key=/tmp/ckad-sec-05/tls.key
```

`kubectl create secret generic --from-file=tls.crt=...` reste de type Opaque.
Un Ingress TLS ne le prend pas.

---

## sec-06 — Montage TLS

Le script crée `web-tls`. Ajouter le volume au Deployment existant :

```yaml
volumeMounts:
  - name: certs
    mountPath: /etc/nginx/certs
    readOnly: true
volumes:
  - name: certs
    secret:
      secretName: web-tls
```

Puis `kubectl rollout status deployment/gateway -n ckad-sec-06`. Les Pods de
l'ancienne révision n'ont pas le montage.
