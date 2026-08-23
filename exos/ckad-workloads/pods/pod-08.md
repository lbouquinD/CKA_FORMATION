# pod-08 — Sidecar et volume partagé

Niveau 2

Contexte : namespace `ckad-pod-08`.

Créez un Pod `sidecar-logger` composé de deux conteneurs partageant un volume
`emptyDir` nommé `shared-logs`, monté sur `/var/log/shared`.

- `writer`, image `busybox:1.36`, écrit la date toutes les 5 secondes dans
  `/var/log/shared/app.log`;
- `reader`, image `busybox:1.36`, suit en continu le fichier avec `tail -F`;
- les deux conteneurs doivent rester actifs et devenir `Ready`.

Le fichier doit être réellement lisible depuis le conteneur `reader`.
