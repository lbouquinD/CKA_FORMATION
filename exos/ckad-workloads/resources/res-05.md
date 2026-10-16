# res-05 — Tenir dans la quota

Niveau 3 — 20 minutes

Contexte : namespace `ckad-res-05`.

Préparez le scénario avec `./lab.sh start res-05`. La ResourceQuota
`team-quota` est en place et le Deployment `api` demande trop : des Pods
restent en attente.

Ne modifiez pas la quota. Ajustez le Deployment :

- 2 réplicas, label `app=api` ;
- conteneur `api`, image `nginx:1.27.3` ;
- requests : `cpu: 50m`, `memory: 32Mi` ;
- limits : `cpu: 100m`, `memory: 64Mi` ;
- 2 réplicas à jour et disponibles.

Les événements du ReplicaSet indiquent le plafond dépassé. Retirer le bloc
`resources` ne fait pas passer l'admission : sans request, la quota refuse
aussi le Pod.
