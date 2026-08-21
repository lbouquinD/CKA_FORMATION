# sts-04 — Mise à jour partitionnée

Niveau 3 — 25 minutes

Contexte : namespace `ckad-sts-04`.

Préparez le scénario avec `./lab.sh start sts-04`.

Faites évoluer le StatefulSet `rolling-db` :

- passez à 4 réplicas;
- définissez une stratégie `RollingUpdate` avec `partition: 2`;
- changez l'image du template vers `nginx:1.27.3`;
- attendez que `rolling-db-2` et `rolling-db-3` utilisent la nouvelle image;
- les Pods d'ordinal inférieur à 2 doivent conserver l'ancienne image;
- les 4 réplicas doivent être disponibles.
