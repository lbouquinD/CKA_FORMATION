# deploy-01 — Créer un Deployment

Niveau 1 — 15 minutes

Contexte : namespace `ckad-deploy-01`.

Créez un Deployment `web` avec :

- 3 réplicas;
- labels et sélecteur `app=web`;
- conteneur `nginx`, image `nginx:1.27.3`, port déclaré `80`;
- 3 réplicas disponibles.

La ressource doit être gérée par un Deployment, pas par un ReplicaSet créé
directement.
