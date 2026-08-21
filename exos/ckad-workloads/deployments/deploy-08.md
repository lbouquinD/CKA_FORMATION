# deploy-08 — Déploiement canary

Niveau 3 — 30 minutes

Contexte : namespace `ckad-deploy-08`.

Créez deux Deployments représentant une diffusion canary :

- `frontend-stable` : 4 réplicas, image `nginx:1.26.3`;
- `frontend-canary` : 1 réplica, image `nginx:1.27.3`;
- les deux templates portent `app=frontend`;
- `track=stable` distingue le stable et `track=canary` le canary;
- chaque Deployment doit sélectionner ses propres labels `app` et `track`;
- tous les réplicas doivent être disponibles.

Enregistrez les noms des deux Deployments, triés, dans
`/tmp/ckad-deploy-08.txt`.
