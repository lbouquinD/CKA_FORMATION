# sec-06 — Monter un Secret TLS

Niveau 3 — 20 minutes

Contexte : namespace `ckad-sec-06`.

Préparez le scénario avec `./lab.sh start sec-06`. Il crée le Secret TLS
`web-tls` et un Deployment `gateway` déjà disponible (2 réplicas nginx).

Montez ce Secret dans le conteneur `nginx` :

- volume `certs`, issu de `web-tls` ;
- montage `/etc/nginx/certs`, en lecture seule ;
- `tls.crt` et `tls.key` sont lisibles dans les Pods à jour.

Conservez l'image `nginx:1.27.3`, le label `app=gateway`, le type du Secret
et 2 réplicas disponibles. Attendez la fin du rollout avant de valider.
