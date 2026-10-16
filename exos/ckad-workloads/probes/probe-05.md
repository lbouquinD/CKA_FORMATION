# probe-05 — Réparer les sondes

Niveau 3 — 20 minutes

Contexte : namespace `ckad-probe-05`.

Préparez le scénario avec `./lab.sh start probe-05`.

Le Deployment `shop` ne reste pas disponible : ses sondes ne visent pas le
port écouté par nginx. Corrigez le template sans changer le nom, l'image
`nginx:1.27.3`, le conteneur `web`, le label `app=shop` ni les 2 réplicas.

État final :

- readinessProbe HTTP sur `/`, port `80`, `initialDelaySeconds: 3`,
  `periodSeconds: 5` ;
- livenessProbe HTTP sur `/`, port `80`, `initialDelaySeconds: 5`,
  `periodSeconds: 10` ;
- startupProbe HTTP sur `/`, port `80`, `periodSeconds: 5`,
  `failureThreshold: 6` ;
- 2 réplicas à jour et disponibles.
