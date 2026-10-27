# Corrections — ServiceAccounts

Fichier formateur. Ne pas ouvrir pendant la session stagiaire.

Un ServiceAccount est l'identité d'un Pod face à l'API. Son nom complet est
`system:serviceaccount:<namespace>:<nom>`. Depuis 1.24, le jeton monté dans un
Pod est un jeton projeté, de durée limitée, renouvelé par le kubelet. Aucun
Secret de jeton n'est plus créé automatiquement.

---

## sa-01 — Identité d'un Pod

```bash
kubectl create serviceaccount build-bot -n ckad-sa-01
kubectl run builder -n ckad-sa-01 --image=busybox:1.36 \
  --overrides='{"spec":{"serviceAccountName":"build-bot"}}' -- sleep 3600
```

Le conteneur créé par `kubectl run builder` s'appelle `builder`. Version
manifeste :

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: builder
spec:
  serviceAccountName: build-bot
  containers:
    - name: builder
      image: busybox:1.36
      command: ["sleep", "3600"]
```

`serviceAccountName` ne se modifie pas sur un Pod existant. Il faut supprimer
et recréer le Pod.

---

## sa-02 — Pas de jeton monté

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: quiet-sa
automountServiceAccountToken: false
---
apiVersion: v1
kind: Pod
metadata:
  name: no-token
spec:
  serviceAccountName: quiet-sa
  containers:
    - name: app
      image: busybox:1.36
      command: ["sleep", "3600"]
```

Vérification :
`kubectl exec -n ckad-sa-02 no-token -- ls /var/run/secrets/kubernetes.io/serviceaccount`
doit échouer.

`automountServiceAccountToken: true` dans le spec du Pod l'emporte sur le
ServiceAccount. Un Pod créé avant le changement garde son montage.

---

## sa-03 — Jetons pour la CI

```bash
kubectl create serviceaccount ci -n ckad-sa-03
kubectl create token ci -n ckad-sa-03 --duration=2h > /tmp/ckad-sa-03.txt
```

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: ci-token
  namespace: ckad-sa-03
  annotations:
    kubernetes.io/service-account.name: ci
type: kubernetes.io/service-account-token
```

Le contrôleur de jetons remplit `data.token`, `data.ca.crt` et
`data.namespace` :
`kubectl get secret ci-token -n ckad-sa-03 -o jsonpath='{.data.token}' | base64 -d`.

Le jeton de `kubectl create token` n'est stocké nulle part. Pour lire ses
claims, décodez la partie centrale du JWT (base64url) : `sub` vaut
`system:serviceaccount:ckad-sa-03:ci` et `exp - iat` vaut 7200.

---

## sa-04 — Changer l'identité d'un Deployment

```bash
kubectl create serviceaccount reporter-sa -n ckad-sa-04
kubectl set serviceaccount deployment/reporter reporter-sa -n ckad-sa-04
kubectl rollout status deployment/reporter -n ckad-sa-04
kubectl get pods -n ckad-sa-04 -o custom-columns=NAME:.metadata.name,SA:.spec.serviceAccountName
```

Le changement porte sur le template. Le rollout recrée les Pods.

---

## sa-05 — Jeton projeté pour un tiers

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: audience-app
spec:
  serviceAccountName: api-client
  containers:
    - name: app
      image: busybox:1.36
      command: ["sleep", "3600"]
      volumeMounts:
        - name: vault-token
          mountPath: /var/run/secrets/vault
          readOnly: true
  volumes:
    - name: vault-token
      projected:
        sources:
          - serviceAccountToken:
              audience: vault
              expirationSeconds: 3600
              path: token
```

`expirationSeconds` doit valoir au moins 600. Le kubelet renouvelle le jeton
avant son expiration. La claim `aud` du JWT vaut `["vault"]`. Le jeton
habituel reste monté à côté.
