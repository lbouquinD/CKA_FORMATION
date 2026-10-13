# ing-01 — Ingress vers un Service

Niveau 1 — 15 minutes

Contexte : namespace `ckad-ing-01`.

Lancez une fois `./init.sh` : il installe le contrôleur et l'IngressClass
`ckad`. Puis `./lab.sh start ing-01`.

Le Service `web` expose déjà nginx sur le port `80`.

Créez un Ingress `web` :

- `ingressClassName: ckad`;
- hôte `web.ckad.local`;
- chemin `/`, `pathType: Prefix`;
- backend : Service `web`, port `80`.

Le backend d'un Ingress est un Service, pas un Deployment.
