# rbac-02 — Compte de déploiement

Niveau 2 — 12 minutes

Contexte : namespace `ckad-rbac-02`.

Un pipeline doit déployer dans ce namespace, et seulement dans celui-ci.

1. Créez le ServiceAccount `deployer`.
2. Créez le Role `deployer` :
   - Deployments : `get`, `list`, `create`, `update`, `patch`, `delete` ;
   - Pods : `get`, `list`.
3. Créez le RoleBinding `deployer` qui donne ce Role au ServiceAccount
   `deployer`.

`deployer` ne peut ni supprimer un Pod ni lire un Secret.
