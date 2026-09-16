# vol-01 — Volume emptyDir

Niveau 1 — 10 minutes

Contexte : namespace `ckad-vol-01`.

Créez un Pod `scratch-box` avec :

- label `app=scratch`;
- un seul conteneur `box`, image `busybox:1.36`, qui reste actif (`sleep 3600`);
- un volume `emptyDir` nommé `scratch`, monté sur `/scratch`;
- un fichier `/scratch/ready.txt` contenant exactement `CKAD-VOL`;
- le Pod doit être `Ready`.
