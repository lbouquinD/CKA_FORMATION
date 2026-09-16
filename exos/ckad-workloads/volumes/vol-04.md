# vol-04 — PVC et Pod

Niveau 2 — 20 minutes

Contexte : namespace `ckad-vol-04`.

Créez :

1. un PersistentVolumeClaim `app-data` :
   - `50Mi`;
   - `ReadWriteOnce`;
   - StorageClass `local-path` (provisioner local);
2. un Pod `app-storage` :
   - label `app=storage`;
   - conteneur `app`, image `busybox:1.36`, qui reste actif (`sleep 3600`);
   - volume `data` utilisant le PVC `app-data`, monté sur `/data`.

Le PVC doit être `Bound` et le Pod `Ready`.
