# pod-05 — Réparer les sondes

Niveau 3 — 20 minutes

Contexte : namespace `ckad-pod-05`.

Préparez le scénario avec `./lab.sh start pod-05`.

Le Pod `probe-web` fonctionne, mais ne devient jamais `Ready`. Corrigez sa
configuration sans changer son nom, son image ni son port.
Si un champ de Pod est immuable, recréez la ressource avec le même nom.

État final attendu :

- une readiness probe HTTP valide sur `/` et le port `80`;
- une liveness probe HTTP valide sur `/` et le port `80`;
- `initialDelaySeconds` vaut `2` pour les deux sondes;
- le Pod est `Ready`.
