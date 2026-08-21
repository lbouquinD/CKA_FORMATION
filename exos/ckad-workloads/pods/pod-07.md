# pod-07 — Image et environnement

Niveau 3 — 20 minutes

Contexte : namespace `ckad-pod-07`.

Préparez le scénario avec `./lab.sh start pod-07`.

Le Pod `configured-app` ne démarre pas et sa configuration applicative est
incomplète. Réparez-le sans changer son nom.
Recréez le Pod avec le même nom si les champs à corriger sont immuables.

État final :

- conteneur `app`, image `busybox:1.36`;
- commande `sh -c` exécutant une boucle de sommeil durable;
- variable `APP_MODE` ayant la valeur `production`;
- variable `POD_NAME` alimentée depuis `metadata.name` avec la Downward API;
- Pod `Ready`.
