# probe-01 — Sondes HTTP

Niveau 1 — 15 minutes

Contexte : namespace `ckad-probe-01`.

Créez un Pod `web` avec un conteneur `nginx`, image `nginx:1.27.3`.

- readinessProbe HTTP sur le chemin `/`, port `80`, `initialDelaySeconds: 2`,
  `periodSeconds: 5` ;
- livenessProbe HTTP sur le chemin `/`, port `80`, `initialDelaySeconds: 5`,
  `periodSeconds: 10` ;
- le Pod est `Ready`.

Le port de la sonde est le port écouté par le conteneur.
