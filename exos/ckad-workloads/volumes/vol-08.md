# vol-08 — Deployment et PVC

Niveau 2 — 20 minutes

Contexte : namespace `ckad-vol-08`.

Créez :

1. un PVC `web-content` : `50Mi`, `ReadWriteOnce`, StorageClass `local-path`;
2. un Deployment `static-web` de **1** réplica (le volume est `ReadWriteOnce`) :
   - labels et sélecteur `app=static-web`;
   - conteneur `nginx`, image `nginx:1.27.3`;
   - volume `content` utilisant le PVC `web-content`, monté sur
     `/usr/share/nginx/html`.

Écrivez `/usr/share/nginx/html/index.html` contenant exactement
`CKAD pvc web`. Le replica doit être disponible, le PVC `Bound`.
