# pod-08 — Observer, lister et supprimer

Niveau 2 — 20 minutes

Contexte : namespace `ckad-pod-08`.

Préparez le scénario avec `./lab.sh start pod-08`, puis réalisez les opérations :

1. Enregistrez les logs du conteneur `reporter` du Pod `ops-reporter` dans
   `/tmp/ckad-pod-08`.
2. Listez les Pods du namespace sous la forme `NOM IMAGE PHASE`, sans en-tête,
   triés par nom, dans `/tmp/ckad-pod-08.txt`.
3. Supprimez uniquement le Pod `obsolete-pod`.

Le Pod `ops-reporter` doit rester actif. Ne supprimez pas le namespace.
