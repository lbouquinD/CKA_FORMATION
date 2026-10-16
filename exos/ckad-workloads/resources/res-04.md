# res-04 — ResourceQuota

Niveau 2 — 18 minutes

Contexte : namespace `ckad-res-04`.

Créez une ResourceQuota `team-quota` :

- `pods: "4"` ;
- `requests.cpu: 500m` ;
- `requests.memory: 256Mi` ;
- `limits.cpu: "1"` ;
- `limits.memory: 512Mi`.

Créez ensuite un Deployment `web` :

- 2 réplicas, label `app=web` ;
- conteneur `nginx`, image `nginx:1.27.3` ;
- requests : `cpu: 100m`, `memory: 64Mi` ;
- limits : `cpu: 200m`, `memory: 128Mi` ;
- 2 réplicas disponibles.

Dès qu'une quota compte les requests, un conteneur sans request est refusé.
Le produit réplicas × request doit rester sous le plafond.
`kubectl describe resourcequota` montre `hard` et `used`.
