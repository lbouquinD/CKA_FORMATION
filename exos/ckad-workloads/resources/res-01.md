# res-01 — Requests et limits

Niveau 1 — 12 minutes

Contexte : namespace `ckad-res-01`.

Créez un Pod `api` avec un conteneur `api`, image `nginx:1.27.3`.

- requests : `cpu: 100m`, `memory: 64Mi` ;
- limits : `cpu: 200m`, `memory: 128Mi` ;
- le Pod est `Ready`.

`requests` est le plancher annoncé au scheduler. `limits` est le plafond du
conteneur. Une limit inférieure à la request du même type est refusée.
