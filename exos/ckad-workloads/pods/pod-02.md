# pod-02 — Métadonnées et ressources

Niveau 1 — 15 minutes

Contexte : namespace `ckad-pod-02`.

Créez un Pod `api-limited` utilisant `nginx:1.27.3`, avec un conteneur `api`.

- labels : `app=api` et `tier=backend`;
- annotation : `training.ckad/owner=team-blue`;
- requêtes : `cpu=50m`, `memory=32Mi`;
- limites : `cpu=100m`, `memory=64Mi`;
- politique de redémarrage `Always`.

Le Pod doit être `Ready`.
