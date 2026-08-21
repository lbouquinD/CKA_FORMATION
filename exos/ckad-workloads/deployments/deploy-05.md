# deploy-05 — Stratégie de disponibilité

Niveau 2 — 20 minutes

Contexte : namespace `ckad-deploy-05`.

Créez un Deployment `critical-api` de 4 réplicas, image `nginx:1.27.3`,
conteneur `api` et label `app=critical-api`.

Configurez explicitement une stratégie `RollingUpdate` garantissant :

- aucun Pod indisponible pendant la mise à jour (`maxUnavailable: 0`);
- au plus un Pod supplémentaire (`maxSurge: 1`);
- `revisionHistoryLimit: 5`;
- 4 réplicas disponibles à la fin.
