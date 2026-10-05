# svc-11 — Canary

Niveau 2 — 25 minutes

Contexte : namespace `ckad-svc-11`.

Diffusez une version canary derrière un seul Service.

1. Deployment `catalog-stable` : 3 réplicas, image `nginx:1.26.3`,
   conteneur `nginx`;
2. Deployment `catalog-canary` : 1 réplica, image `nginx:1.27.3`,
   conteneur `nginx`;
3. les deux Pods portent `app=catalog`;
4. `track=stable` pour le stable, `track=canary` pour le canary;
5. chaque Deployment sélectionne **ses** labels `app` et `track`
   (ils ne doivent pas se voler les Pods);
6. Service `catalog`, type `ClusterIP`, port `80`, `targetPort` `80`,
   sélecteur `app=catalog` uniquement (pas de `track`).

Les quatre réplicas doivent être disponibles. Le Service doit avoir quatre
Endpoints : le trafic est réparti au prorata des Pods (3 stables, 1 canary).
