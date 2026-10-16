# sec-05 — Secret TLS

Niveau 2 — 15 minutes

Contexte : namespace `ckad-sec-05`.

Préparez le scénario avec `./lab.sh start sec-05`. `openssl` doit être
disponible sur la machine qui lance le script. Deux fichiers sont alors prêts :

- `/tmp/ckad-sec-05/tls.crt`
- `/tmp/ckad-sec-05/tls.key`

Le certificat est émis pour `shop.ckad.local`.

Créez un Secret TLS `shop-tls` à partir de ces fichiers. Son type est
`kubernetes.io/tls`, et ses clés sont `tls.crt` et `tls.key`.
