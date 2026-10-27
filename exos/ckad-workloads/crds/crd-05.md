# crd-05 — Ressource de cluster

Niveau 2 — 18 minutes

Contexte : namespace `ckad-crd-05` (non utilisé par les objets demandés).

Créez la CustomResourceDefinition des régions :

- groupe : `crd05.ckad.io` ;
- kind : `Region`, pluriel `regions`, singulier `region`, nom court `rg` ;
- ressource de **cluster**, sans namespace ;
- une seule version, `v1`, servie et stockée, avec la sous-ressource `status` ;
- champ `spec.code` : chaîne de trois lettres minuscules exactement (motif
  `^[a-z]{3}$`).

Créez ensuite la `Region` `eu-west` avec `code: euw`.
