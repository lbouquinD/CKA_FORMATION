# pod-09 — Initialisation avant démarrage

Niveau 2

Contexte : namespace `ckad-pod-09`.

Créez un Pod `initialized-web` avec un volume `emptyDir` nommé `web-content`.

- un init container `prepare`, image `busybox:1.36`, crée
  `/work/index.html` contenant le texte `CKAD initialized`;
- le conteneur principal `web`, image `nginx:1.27.3`, monte le même volume sur
  `/usr/share/nginx/html`;
- le Pod doit être `Ready`;
- une requête locale sur le port 80 doit renvoyer le contenu préparé.
