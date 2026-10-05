# svc-02 — Service NodePort

Niveau 1 — 15 minutes

Contexte : namespace `ckad-svc-02`.

Préparez le scénario avec `./lab.sh start svc-02`.

Le Deployment `api` est déjà en place (label `app=api`, conteneur nginx sur
le port `80`).

Créez un Service `api-node` :

- type `NodePort`;
- sélecteur `app=api`;
- port `80`, `targetPort` `80`;
- `nodePort` `30080`.

Le Service doit avoir des Endpoints prêts.
