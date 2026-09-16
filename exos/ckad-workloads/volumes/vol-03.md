# vol-03 — emptyDir partagé dans un Deployment

Niveau 2 — 20 minutes

Contexte : namespace `ckad-vol-03`.

Créez un Deployment `share-html` de 1 réplica, labels et sélecteur `app=share-html`.

Les deux conteneurs partagent un volume `emptyDir` nommé `html` :

- `loader`, image `busybox:1.36`, écrit `/work/index.html` contenant
  `CKAD shared volume` puis reste actif;
- `web`, image `nginx:1.27.3`, monte le même volume sur
  `/usr/share/nginx/html`.

Le replica doit être disponible. Le fichier doit être lisible depuis le
conteneur `web`.
