# svc-10 — Convertir en LoadBalancer

Niveau 2 — 10 minutes

Contexte : namespace `ckad-svc-10`.

Préparez le scénario avec `./lab.sh start svc-10`.

Le Service `edge` est un `ClusterIP`. Passez-le en `LoadBalancer` sans
changer son nom, son sélecteur ni ses ports.

État final :

- type `LoadBalancer`;
- sélecteur `app=edge`;
- port `80`, `targetPort` `80`;
- Endpoints prêts.
