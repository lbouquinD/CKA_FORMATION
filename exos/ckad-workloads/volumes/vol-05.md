# vol-05 — Persistance d'un PVC

Niveau 2 — 20 minutes

Contexte : namespace `ckad-vol-05`.

Créez un PVC `keep-data` (`100Mi`, `ReadWriteOnce`, StorageClass `local-path`)
et un Pod `keep-pod` qui le monte sur `/data` (conteneur `app`, image
`busybox:1.36`, volume nommé `data`).

- écrivez `/data/marker` contenant exactement `persisted`;
- supprimez le Pod `keep-pod`;
- recréez le même Pod, branché sur le même PVC;
- le fichier doit encore être présent après recréation;
- le PVC doit être `Bound` et le Pod `Ready`.
