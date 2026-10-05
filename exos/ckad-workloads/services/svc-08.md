# svc-08 — Réparer le targetPort

Niveau 3 — 15 minutes

Contexte : namespace `ckad-svc-08`.

Préparez le scénario avec `./lab.sh start svc-08`.

Le Service `payments` sélectionne les bons Pods, mais son `targetPort` ne
correspond pas au port du conteneur nginx (`80`). Corrigez-le sans changer le
nom du Service, son sélecteur ni son port d'écoute.

État final :

- sélecteur `app=payments`;
- type `ClusterIP`, port `80`, `targetPort` `80`;
- les Endpoints exposent le port `80`.
