# sec-04 — Projection partielle

Niveau 2 — 18 minutes

Contexte : namespace `ckad-sec-04`.

Préparez le scénario avec `./lab.sh start sec-04`. Le Secret `app-config`
contient trois clés : `config.properties`, `token` et `note`.

Créez un Pod `config-reader` :

- conteneur `box`, image `busybox:1.36`, qui reste actif (`sleep 3600`) ;
- volume `settings` issu du Secret `app-config` ;
- seules `config.properties` et `token` sont projetées, chacune sous son nom
  de clé ;
- montage sur `/etc/settings`, en lecture seule ;
- `defaultMode` : `0400` ;
- le Pod est `Ready`.

Le fichier `note` ne doit pas apparaître dans `/etc/settings`. Laissez cette
clé dans le Secret.
