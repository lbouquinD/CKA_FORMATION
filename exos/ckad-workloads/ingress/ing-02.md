# ing-02 — Routage par chemin

Niveau 2 — 20 minutes

Contexte : namespace `ckad-ing-02`.

`./init.sh` une fois, puis `./lab.sh start ing-02`.

Deux Services écoutent sur le port `80` : `shop` et `api`.

Créez un Ingress `shop` :

- classe `ckad`;
- hôte `shop.ckad.local`;
- `/` en `Prefix` vers le Service `shop:80`;
- `/api` en `Prefix` vers le Service `api:80`.

Chaque chemin est une entrée distincte de `http.paths`.
