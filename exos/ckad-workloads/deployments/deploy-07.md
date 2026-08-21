# deploy-07 — Sélecteur immuable

Niveau 3 — 20 minutes

Contexte : namespace `ckad-deploy-07`.

Préparez le scénario avec `./lab.sh start deploy-07`.

Le Deployment `orders` porte encore le sélecteur de l'ancienne application.
Corrigez-le pour que le sélecteur et le template utilisent exactement
`app=orders`, tout en conservant :

- le nom `orders`;
- 2 réplicas;
- le conteneur `orders` avec `nginx:1.27.3`;
- 2 réplicas disponibles.

Traitez correctement l'immutabilité du sélecteur.
