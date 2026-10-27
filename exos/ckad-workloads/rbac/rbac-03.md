# rbac-03 — Droits fins et droits globaux

Niveau 3 — 20 minutes

Contexte : namespace `ckad-rbac-03`.

Créez le ServiceAccount `log-reader` et donnez-lui exactement ces droits.

Dans le namespace `ckad-rbac-03` (Role et RoleBinding nommés `log-reader`) :

- lister les Pods et lire leurs logs ;
- ne pas pouvoir exécuter une commande dans un Pod (`kubectl exec`) ;
- créer des Secrets, sans pouvoir les lister ni les lire.

Sur tout le cluster (ClusterRole et ClusterRoleBinding nommés
`rbac-03-ns-lister`) :

- lister les Namespaces, et rien d'autre.

Les droits sur les Pods et les Secrets ne doivent pas s'appliquer aux autres
namespaces.
