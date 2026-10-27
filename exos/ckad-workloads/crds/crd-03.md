# crd-03 — Faire évoluer une CRD

Niveau 2 — 18 minutes

Contexte : namespace `ckad-crd-03`.

Préparez le scénario avec `./lab.sh start crd-03`. La CRD
`backups.crd03.ckad.io` existe avec un seul champ, `spec.schedule`.

1. Ajoutez à la version `v1` le champ `spec.retention` : un entier d'au moins
   `1`.
2. `kubectl get backups` doit afficher deux colonnes en plus :
   - `Schedule` (type `string`) : valeur de `spec.schedule` ;
   - `Retention` (type `integer`) : valeur de `spec.retention`.
3. Créez le `Backup` `nightly` avec `schedule: "0 2 * * *"` et `retention: 7`.

Un `Backup` avec `retention: 0` doit être refusé.
