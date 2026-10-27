# crd-04 — Manifeste refusé

Niveau 3 — 15 minutes

Contexte : namespace `ckad-crd-04`.

Préparez le scénario avec `./lab.sh start crd-04`. Un collègue a écrit
`/tmp/ckad-crd-04/widget.yaml`, mais
`kubectl apply -n ckad-crd-04 -f /tmp/ckad-crd-04/widget.yaml` échoue.

1. Corrigez le fichier à son emplacement, en partant de la CRD
   `widgets.crd04.ckad.io`.
2. L'objet `banner` doit être créé avec une taille de `3` et la couleur
   `blue`.

Ne modifiez pas la CRD.
