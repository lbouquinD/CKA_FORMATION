# svc-12 — Blue-green

Niveau 3 — 20 minutes

Contexte : namespace `ckad-svc-12`.

Préparez le scénario avec `./lab.sh start svc-12`.

Deux versions tournent en parallèle :

- `catalog-blue`, image `nginx:1.26.3`, label `version=blue`;
- `catalog-green`, image `nginx:1.27.3`, label `version=green`.

Le Service `catalog` envoie encore le trafic vers le bleu. Basculez-le vers
le vert, sans supprimer les Deployments.

État final :

- sélecteur `app=catalog` et `version=green`;
- type `ClusterIP`, port `80`, `targetPort` `80`;
- les Endpoints ne contiennent que les Pods verts;
- les deux Deployments restent disponibles.
