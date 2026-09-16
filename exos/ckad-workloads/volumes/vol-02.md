# vol-02 — emptyDir en mémoire

Niveau 2 — 15 minutes

Contexte : namespace `ckad-vol-02`.

Créez un Pod `ram-box` avec :

- label `app=ram`;
- un conteneur `box`, image `busybox:1.36`, qui reste actif (`sleep 3600`);
- un volume `emptyDir` nommé `cache`, monté sur `/cache`;
- `medium: Memory`;
- `sizeLimit: 32Mi`;
- un fichier `/cache/ready.txt` contenant exactement `CKAD-RAM`;
- le Pod doit être `Ready`.
