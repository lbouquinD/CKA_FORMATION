# deploy-03 — Rolling update

Niveau 2 — 20 minutes

Contexte : namespace `ckad-deploy-03`.

Préparez le scénario avec `./lab.sh start deploy-03`.

Mettez à jour le Deployment `storefront` vers l'image `nginx:1.27.3`.

- utilisez une mise à jour contrôlée du template;
- annotez le Deployment avec
  `kubernetes.io/change-cause=upgrade to nginx 1.27.3`;
- attendez explicitement la fin du rollout;
- conservez 4 réplicas disponibles.
