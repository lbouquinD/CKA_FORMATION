# pod-01 — Création impérative

Niveau 1

Contexte : namespace `ckad-pod-01`.

Créez un Pod nommé `web-dev` avec l'image `nginx:alpine`.

- label `tier=frontend`;
- variable d'environnement `APP_ENV=development`;
- le Pod doit être `Ready`.

Réalisez la tâche avec une seule commande `kubectl run`, sans fichier YAML
local.
