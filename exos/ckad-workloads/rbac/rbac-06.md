# rbac-06 — Audit de droits

Niveau 2 — 12 minutes

Contexte : namespace `ckad-rbac-06`.

Préparez le scénario avec `./lab.sh start rbac-06`. Le ServiceAccount
`auditor` a déjà des droits. Ne les modifiez pas.

Répondez pour `auditor` aux questions suivantes. Écrivez une réponse par ligne,
dans l'ordre, `yes` ou `no`, dans `/tmp/ckad-rbac-06.txt` :

1. lister les Pods du namespace `ckad-rbac-06` ;
2. supprimer un Pod du namespace `ckad-rbac-06` ;
3. lire un Secret précis (`get`) du namespace `ckad-rbac-06` ;
4. lister les Secrets du namespace `ckad-rbac-06` ;
5. lister les Deployments du namespace `ckad-rbac-06` ;
6. lister les Deployments du namespace `kube-system`.

Le fichier contient 6 lignes et rien d'autre.
