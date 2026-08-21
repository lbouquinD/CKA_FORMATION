# sts-03 — Stockage persistant

Niveau 3 — 30 minutes

Contexte : namespace `ckad-sts-03`.

Créez un Service headless `cache-headless` et un StatefulSet `cache` de
2 réplicas, label `app=cache`.

- conteneur `cache`, image `busybox:1.36`, exécutant `sleep 3600`;
- `volumeClaimTemplates` nommé `data`;
- chaque PVC demande `100Mi`, mode `ReadWriteOnce`;
- utilisez la StorageClass `local-path`;
- montage du volume sur `/data`;
- écrivez un fichier `/data/marker` dans le Pod `cache-0`, supprimez ce Pod et
  vérifiez que le fichier existe encore après recréation;
- les deux Pods doivent être disponibles.
