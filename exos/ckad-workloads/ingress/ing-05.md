# ing-05 — TLS

Niveau 2 — 20 minutes

Contexte : namespace `ckad-ing-05`.

`./init.sh` une fois, puis `./lab.sh start ing-05`.

Le Service `web` écoute sur le port `80`. Un Secret TLS `web-tls` est déjà
créé.

Créez un Ingress `secure` :

- classe `ckad`;
- TLS pour l'hôte `secure.ckad.local` avec le Secret `web-tls`;
- règle HTTP : hôte `secure.ckad.local`, chemin `/`, `Prefix`, Service `web:80`.

La section `tls` ne remplace pas la règle `rules` : les deux sont nécessaires.
