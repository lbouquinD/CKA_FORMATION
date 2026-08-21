# deploy-06 — Diagnostic croisé

Niveau 3 — 25 minutes

Contexte : namespace `ckad-deploy-06`.

Préparez le scénario avec `./lab.sh start deploy-06`.

Le Deployment `broken-api` n'a aucun replica disponible. Corrigez toutes les
causes sans changer son nom ni le nombre de réplicas.

État final :

- 3 réplicas, conteneur `api`, image `nginx:1.27.3`;
- aucune commande personnalisée ne remplace l'entrée nginx;
- readiness probe HTTP sur `/` port `80`;
- limites `cpu=200m` et `memory=128Mi`;
- rollout terminé avec 3 réplicas disponibles.
