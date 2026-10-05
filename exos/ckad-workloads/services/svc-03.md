# svc-03 — Réparer le sélecteur

Niveau 3 — 15 minutes

Contexte : namespace `ckad-svc-03`.

Préparez le scénario avec `./lab.sh start svc-03`.

Le Deployment `shop` est disponible, mais le Service `shop` n'a aucun
Endpoint. Corrigez le Service sans changer son nom, son type ni son port.

État final :

- sélecteur `app=shop`;
- type `ClusterIP`, port `80`, `targetPort` `80`;
- des Endpoints prêts sont présents.
