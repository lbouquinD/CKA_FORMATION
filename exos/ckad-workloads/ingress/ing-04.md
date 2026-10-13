# ing-04 — Deux hôtes

Niveau 2 — 20 minutes

Contexte : namespace `ckad-ing-04`.

`./init.sh` une fois, puis `./lab.sh start ing-04`.

Les Services `blue` et `green` écoutent sur le port `80`.

Créez un Ingress `colors`, classe `ckad`, avec deux règles :

- hôte `blue.ckad.local`, chemin `/`, `Prefix`, Service `blue:80`;
- hôte `green.ckad.local`, chemin `/`, `Prefix`, Service `green:80`.

Un hôte correspond à une entrée de `spec.rules`, pas à un second Ingress.
