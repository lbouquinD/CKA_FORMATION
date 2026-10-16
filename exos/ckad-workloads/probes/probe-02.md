# probe-02 — Sonde exec

Niveau 1 — 15 minutes

Contexte : namespace `ckad-probe-02`.

Créez un Pod `worker` avec un conteneur `box`, image `busybox:1.36`.

La commande du conteneur crée le fichier `/tmp/healthy`, puis reste active
(`sleep 3600`).

- livenessProbe et readinessProbe exécutent `cat /tmp/healthy` ;
- `initialDelaySeconds: 5` et `periodSeconds: 10` pour les deux sondes ;
- le Pod est `Ready`, sans redémarrages en boucle.

Une sonde exec est réussie quand la commande se termine avec le code 0.
