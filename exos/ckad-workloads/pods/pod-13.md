# pod-13 — Observer, lister et supprimer

Niveau 2

Contexte : namespace `ckad-pod-13`.

Préparez le scénario avec `./lab.sh start pod-13`, puis réalisez les opérations :

1. Enregistrez les logs du conteneur `reporter` du Pod `ops-reporter` dans
   `/tmp/ckad-pod-13`.
2. Listez les Pods du namespace sous la forme `NOM IMAGE PHASE`, sans en-tête,
   triés par nom, dans `/tmp/ckad-pod-13.txt`.
3. Supprimez uniquement le Pod `obsolete-pod`.

Le Pod `ops-reporter` doit rester actif. Ne supprimez pas le namespace.
