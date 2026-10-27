# rbac-04 — Droits refusés

Niveau 3 — 15 minutes

Contexte : namespace `ckad-rbac-04`.

Préparez le scénario avec `./lab.sh start rbac-04`. Le Pod `metrics-agent`
tourne avec le ServiceAccount `metrics`. Ses appels à l'API sont refusés
(`403 Forbidden`).

Corrigez le Role `metrics-reader` et le RoleBinding `metrics-reader` pour que
`metrics` puisse faire `get`, `list` et `watch` sur les Pods et les Services du
namespace.

Gardez les noms existants. `metrics` reste en lecture seule.
