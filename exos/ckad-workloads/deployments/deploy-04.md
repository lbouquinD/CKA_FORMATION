# deploy-04 — Revenir à une révision stable

Niveau 3 — 20 minutes

Contexte : namespace `ckad-deploy-04`.

Préparez le scénario avec `./lab.sh start deploy-04`.

Le Deployment `payments` a subi plusieurs mises à jour. La révision portant
l'annotation `stable release` était fonctionnelle. Revenez à cette révision en
utilisant l'historique de rollout.

Contraintes :

- ne recréez pas le Deployment;
- 3 réplicas doivent être disponibles;
- l'image finale doit être celle de la révision stable;
- l'historique doit rester consultable.
