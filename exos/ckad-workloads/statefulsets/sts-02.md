# sts-02 — Initialisation ordonnée

Niveau 2 — 25 minutes

Contexte : namespace `ckad-sts-02`.

Créez un Service headless `db-headless` et un StatefulSet `db` de 3 réplicas.

- labels et sélecteur : `app=db`;
- `serviceName: db-headless`;
- `podManagementPolicy: OrderedReady`;
- init container `identity`, image `busybox:1.36`, qui écrit le hostname dans
  `/data/identity`;
- conteneur `database`, image `busybox:1.36`, exécutant `sleep 3600`;
- volume `emptyDir` nommé `data`, partagé sur `/data`;
- les trois Pods ordonnés doivent être disponibles.
