# svc-05 — targetPort nommé

Niveau 2 — 15 minutes

Contexte : namespace `ckad-svc-05`.

Préparez le scénario avec `./lab.sh start svc-05`.

Le Deployment `named-web` déclare un `containerPort` nommé `web` (port `80`).

Créez un Service `named-web` :

- type `ClusterIP`;
- sélecteur `app=named-web`;
- port `80`;
- `targetPort` égal au **nom** `web` (pas au numéro `80`).

Le Service doit avoir des Endpoints prêts.
