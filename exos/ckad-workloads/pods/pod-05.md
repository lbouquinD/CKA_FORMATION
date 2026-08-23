# pod-05 — Suppression ciblée et nettoyage forcé

Niveau 1

Contexte : namespace `ckad-pod-05`.

Préparez le scénario avec `./lab.sh start pod-05`.

1. Supprimez tous les Pods portant le label `stage=test` en une seule commande.
2. Supprimez immédiatement le Pod restant `box-check`, sans attendre la période
   de grâce, en mode force.

Ne supprimez pas le namespace.
