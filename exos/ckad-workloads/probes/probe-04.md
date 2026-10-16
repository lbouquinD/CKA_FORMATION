# probe-04 — startupProbe

Niveau 2 — 15 minutes

Contexte : namespace `ckad-probe-04`.

Créez un Pod `web` avec un conteneur `nginx`, image `nginx:1.27.3`.

- startupProbe HTTP sur `/`, port `80`, `periodSeconds: 5`,
  `failureThreshold: 12` ;
- livenessProbe HTTP sur `/`, port `80`, `periodSeconds: 10` ;
- readinessProbe HTTP sur `/`, port `80`, `periodSeconds: 5` ;
- le Pod est `Ready`.

Tant que la startupProbe n'a pas réussi, la liveness et la readiness ne
comptent pas. `failureThreshold` × `periodSeconds` est le temps accordé au
démarrage.
