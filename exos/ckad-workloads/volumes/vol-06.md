# vol-06 — ConfigMap monté en volume

Niveau 2 — 15 minutes

Contexte : namespace `ckad-vol-06`.

Préparez le scénario avec `./lab.sh start vol-06`.

Un ConfigMap `app-config` existe déjà. Créez un Pod `config-reader` qui
l'expose en volume, sans recopier le contenu à la main.

- label `app=config`;
- conteneur `reader`, image `busybox:1.36`, qui reste actif (`sleep 3600`);
- volume `config` de type `configMap`, source `app-config`;
- montage sur `/etc/app`;
- le fichier `/etc/app/app.conf` doit rester lisible;
- le Pod doit être `Ready`.
