# ing-06 — Classe et chemin

Niveau 3 — 15 minutes

Contexte : namespace `ckad-ing-06`.

`./init.sh` une fois, puis `./lab.sh start ing-06`.

L'Ingress `web` est ignoré par le contrôleur, et son chemin n'est pas `/`.

Corrigez-le :

- `ingressClassName: ckad` (la classe créée par `./init.sh`);
- chemin `/`, `pathType: Prefix`;
- backend inchangé : Service `web`, port `80`;
- hôte inchangé : `repair.ckad.local`.

Sans classe, cet Ingress n'est pas pris par le contrôleur du parcours.
