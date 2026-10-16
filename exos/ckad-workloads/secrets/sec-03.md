# sec-03 — Variables depuis un Secret

Niveau 2 — 15 minutes

Contexte : namespace `ckad-sec-03`.

Préparez le scénario avec `./lab.sh start sec-03`. Le Secret `api-token` existe
déjà, avec les clés `user` et `token`. Ne le modifiez pas.

Créez un Pod `client` :

- un conteneur `app`, image `busybox:1.36`, qui reste actif (`sleep 3600`) ;
- la variable `API_USER` alimentée par la clé `user` ;
- la variable `API_TOKEN` alimentée par la clé `token` ;
- le Pod est `Ready`.

Le nom d'une variable et le nom de la clé peuvent différer.
