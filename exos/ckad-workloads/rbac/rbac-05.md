# rbac-05 — ClusterRole et RoleBinding

Niveau 2 — 15 minutes

Contexte : namespace `ckad-rbac-05`.

Un outil d'inventaire tourne avec le ServiceAccount `inventory`.

1. Créez le ServiceAccount `inventory`.
2. `inventory` doit faire `get` et `list` sur les Nodes du cluster. Utilisez un
   ClusterRole et un ClusterRoleBinding nommés `rbac-05-node-viewer`.
3. `inventory` doit aussi lire les objets courants du namespace
   `ckad-rbac-05`. Réutilisez le ClusterRole intégré `view` dans un
   RoleBinding nommé `inventory-view`.

`inventory` ne doit rien lire dans les autres namespaces. Il n'a pas accès aux
Secrets.
