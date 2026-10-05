# svc-09 — Service LoadBalancer

Niveau 1 — 15 minutes

Contexte : namespace `ckad-svc-09`.

Préparez le scénario avec `./lab.sh start svc-09`.

Le Deployment `public` est déjà en place (label `app=public`, nginx sur le
port `80`).

Créez un Service `public-lb` :

- type `LoadBalancer`;
- sélecteur `app=public`;
- port `80`, `targetPort` `80`.

Le Service doit avoir des Endpoints prêts. L'adresse externe peut rester
`Pending` si aucun contrôleur de load balancer n'est installé.
