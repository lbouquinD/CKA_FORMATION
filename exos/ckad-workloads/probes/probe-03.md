# probe-03 — Sonde TCP

Niveau 2 — 12 minutes

Contexte : namespace `ckad-probe-03`.

Créez un Pod `web` avec un conteneur `nginx`, image `nginx:1.27.3`.

- livenessProbe et readinessProbe de type `tcpSocket` sur le port `80` ;
- `periodSeconds: 5` pour les deux ;
- le Pod est `Ready`.

`tcpSocket` vérifie qu'une connexion aboutit. Il ne teste pas un chemin HTTP.
