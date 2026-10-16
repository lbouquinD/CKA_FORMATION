# sec-02 — Secret depuis des fichiers

Niveau 1 — 12 minutes

Contexte : namespace `ckad-sec-02`.

Préparez le scénario avec `./lab.sh start sec-02`. Deux fichiers sont alors
disponibles sur la machine de travail :

- `/tmp/ckad-sec-02/username`
- `/tmp/ckad-sec-02/password`

Créez un Secret Opaque `file-creds`. Les clés `username` et `password` reprennent
le nom de chaque fichier et exactement son contenu.
