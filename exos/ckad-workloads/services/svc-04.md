# svc-04 — Service multi-ports

Niveau 2 — 15 minutes

Contexte : namespace `ckad-svc-04`.

Préparez le scénario avec `./lab.sh start svc-04`.

Le Deployment `gateway` tourne déjà (label `app=gateway`, nginx sur le port
`80`).

Créez un Service `gateway` de type `ClusterIP`, sélecteur `app=gateway`, avec
deux ports nommés qui ciblent tous les deux le port conteneur `80` :

- `http` : port `80`, `targetPort` `80`;
- `admin` : port `8080`, `targetPort` `80`.

Le Service doit avoir des Endpoints prêts.
