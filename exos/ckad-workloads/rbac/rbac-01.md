# rbac-01 — Lecteur de Pods

Niveau 1 — 10 minutes

Contexte : namespace `ckad-rbac-01`.

1. Créez le ServiceAccount `viewer`.
2. Créez le Role `pod-reader` qui permet `get`, `list` et `watch` sur les Pods.
3. Créez le RoleBinding `pod-reader-binding` qui donne ce Role à `viewer`.

`viewer` peut lire les Pods du namespace. Il ne peut ni les créer ni les
supprimer. Contrôlez-le avec `kubectl auth can-i`.
