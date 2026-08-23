# pod-03 — Inspection, filtrage et export YAML

Niveau 1

Contexte : namespace `ckad-pod-03`.

Préparez le scénario avec `./lab.sh start pod-03`.

1. Listez tous les Pods du namespace en affichant leurs labels, sans autre
   transformation, dans `/tmp/ckad-pod-03-labels.txt`.
2. Filtrez pour n'afficher que les Pods ayant le label `tier=ui`, dans
   `/tmp/ckad-pod-03-ui.txt`.
3. Générez un manifeste YAML réutilisable du Pod `web-dev` (sans champs
   système comme `uid` ou `resourceVersion`) dans `/tmp/ckad-pod-03.yaml`.

Utilisez `-l`, `--show-labels` et, pour le manifeste propre,
`--dry-run=client -o yaml`.
