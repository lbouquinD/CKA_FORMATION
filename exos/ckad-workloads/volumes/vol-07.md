# vol-07 — Réparer un PVC bloqué

Niveau 3 — 20 minutes

Contexte : namespace `ckad-vol-07`.

Préparez le scénario avec `./lab.sh start vol-07`.

Le Pod `data-writer` reste en `Pending` : son PVC `broken-data` ne se lie
pas. Corrigez le stockage sans changer les noms du Pod ni du PVC.

État final :

- PVC `broken-data` : `100Mi`, `ReadWriteOnce`, StorageClass `local-path`;
- Pod `data-writer`, conteneur `writer`, image `busybox:1.36`;
- volume `data` monté sur `/data`;
- fichier `/data/ok` contenant exactement `fixed`;
- PVC `Bound`, Pod `Ready`.

Certains champs d'un PVC sont immuables : recréez la ressource si
nécessaire. Si le PVC est utilisé, retirez d'abord le Pod.
