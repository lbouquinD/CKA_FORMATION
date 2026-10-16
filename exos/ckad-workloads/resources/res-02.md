# res-02 — Classe Guaranteed

Niveau 2 — 15 minutes

Contexte : namespace `ckad-res-02`.

Créez un Deployment `billing` :

- 2 réplicas, label `app=billing` ;
- conteneur `app`, image `nginx:1.27.3` ;
- requests et limits identiques : `cpu: 50m`, `memory: 64Mi` ;
- les Pods sont `Ready` et de classe QoS `Guaranteed`.

La classe est calculée par Kubernetes. Elle apparaît dans le statut du Pod.
Elle est `Guaranteed` quand, pour chaque conteneur, chaque request égale la
limit correspondante.
