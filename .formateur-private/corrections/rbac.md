# Corrections — RBAC

Fichier formateur. Ne pas ouvrir pendant la session stagiaire.

- `Role` + `RoleBinding` : droits limités à un namespace.
- `ClusterRole` + `ClusterRoleBinding` : droits sur tout le cluster, y compris
  sur les ressources sans namespace (Nodes, Namespaces, CRD…).
- `ClusterRole` + `RoleBinding` : la règle est réutilisée, mais elle ne
  s'applique que dans le namespace du RoleBinding.

Le groupe core se note `""`. Les Deployments sont dans `apps`. Les
sous-ressources (`pods/log`, `pods/exec`) se déclarent à part.

Pour tester : `kubectl auth can-i <verbe> <ressource> -n <ns> --as=system:serviceaccount:<ns>:<sa>`.
`kubectl auth can-i --list --as=...` affiche tout.

---

## rbac-01 — Lecteur de Pods

```bash
kubectl create serviceaccount viewer -n ckad-rbac-01
kubectl create role pod-reader -n ckad-rbac-01 --verb=get,list,watch --resource=pods
kubectl create rolebinding pod-reader-binding -n ckad-rbac-01 \
  --role=pod-reader --serviceaccount=ckad-rbac-01:viewer
kubectl auth can-i list pods -n ckad-rbac-01 --as=system:serviceaccount:ckad-rbac-01:viewer   # yes
kubectl auth can-i delete pods -n ckad-rbac-01 --as=system:serviceaccount:ckad-rbac-01:viewer # no
```

`--serviceaccount` attend `<namespace>:<nom>`. `--user=viewer` viserait un
utilisateur nommé `viewer`, pas le ServiceAccount.

---

## rbac-02 — Compte de déploiement

```bash
kubectl create serviceaccount deployer -n ckad-rbac-02
kubectl create role deployer -n ckad-rbac-02 \
  --verb=get,list,create,update,patch,delete --resource=deployments.apps
kubectl create rolebinding deployer -n ckad-rbac-02 \
  --role=deployer --serviceaccount=ckad-rbac-02:deployer
```

`kubectl create role` n'accepte qu'un jeu de verbes pour toutes les
ressources. On ajoute la règle des Pods par `kubectl edit role deployer` :

```yaml
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "create", "update", "patch", "delete"]
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]
```

Erreur fréquente : `apiGroups: [""]` pour les Deployments. Le Role est accepté,
mais il ne donne aucun droit.

---

## rbac-03 — Droits fins et droits globaux

```bash
kubectl create serviceaccount log-reader -n ckad-rbac-03
kubectl create clusterrole rbac-03-ns-lister --verb=list --resource=namespaces
kubectl create clusterrolebinding rbac-03-ns-lister \
  --clusterrole=rbac-03-ns-lister --serviceaccount=ckad-rbac-03:log-reader
```

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: log-reader
  namespace: ckad-rbac-03
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["list"]
  - apiGroups: [""]
    resources: ["pods/log"]
    verbs: ["get"]
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["create"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: log-reader
  namespace: ckad-rbac-03
subjects:
  - kind: ServiceAccount
    name: log-reader
    namespace: ckad-rbac-03
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: log-reader
```

Test des sous-ressources : `kubectl auth can-i get pods --subresource=log ...`.
Attention, `kubectl auth can-i get pods/log` répond `no` : la commande le lit
comme le Pod nommé `log`.

`kubectl exec` demande `create` sur `pods/exec`, absent ici. Mettre les règles
Pods/Secrets dans le ClusterRole ouvrirait tous les namespaces.

---

## rbac-04 — Droits refusés

Quatre erreurs dans le scénario :

1. groupe `apps` au lieu de `""` pour Pods et Services ;
2. ressource `pod` au singulier ;
3. verbes : seulement `get` ;
4. subject du RoleBinding dans le namespace `default`.

```bash
kubectl -n ckad-rbac-04 patch role metrics-reader --type=json -p='[
  {"op":"replace","path":"/rules","value":[
    {"apiGroups":[""],"resources":["pods","services"],"verbs":["get","list","watch"]}]}]'
```

`roleRef` d'un binding est immuable, mais `subjects` se modifie :

```bash
kubectl -n ckad-rbac-04 patch rolebinding metrics-reader --type=json \
  -p='[{"op":"replace","path":"/subjects/0/namespace","value":"ckad-rbac-04"}]'
kubectl auth can-i watch pods -n ckad-rbac-04 --as=system:serviceaccount:ckad-rbac-04:metrics
```

---

## rbac-05 — ClusterRole et RoleBinding

```bash
kubectl create serviceaccount inventory -n ckad-rbac-05
kubectl create clusterrole rbac-05-node-viewer --verb=get,list --resource=nodes
kubectl create clusterrolebinding rbac-05-node-viewer \
  --clusterrole=rbac-05-node-viewer --serviceaccount=ckad-rbac-05:inventory
kubectl create rolebinding inventory-view -n ckad-rbac-05 \
  --clusterrole=view --serviceaccount=ckad-rbac-05:inventory
```

Le ClusterRole `view` exclut les Secrets. Lié par RoleBinding, il ne vaut que
dans `ckad-rbac-05`. Un ClusterRoleBinding vers `view` ouvrirait la lecture de
tout le cluster.

---

## rbac-06 — Audit de droits

```bash
SA=system:serviceaccount:ckad-rbac-06:auditor
{
  kubectl auth can-i list pods -n ckad-rbac-06 --as=$SA
  kubectl auth can-i delete pods -n ckad-rbac-06 --as=$SA
  kubectl auth can-i get secrets -n ckad-rbac-06 --as=$SA
  kubectl auth can-i list secrets -n ckad-rbac-06 --as=$SA
  kubectl auth can-i list deployments.apps -n ckad-rbac-06 --as=$SA
  kubectl auth can-i list deployments.apps -n kube-system --as=$SA
} > /tmp/ckad-rbac-06.txt
```

Résultat attendu : `yes no yes no yes no`. Les Deployments viennent du
ClusterRole `rbac-06-deploy-reader`, lié par RoleBinding : il ne vaut que dans
`ckad-rbac-06`. `get` sur les Secrets ne donne pas `list`.
