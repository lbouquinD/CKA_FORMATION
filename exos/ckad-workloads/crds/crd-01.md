# crd-01 — Définir une ressource

Niveau 2 — 20 minutes

Contexte : namespace `ckad-crd-01`.

Créez la CustomResourceDefinition des super-héros :

- groupe : `crd01.ckad.io` ;
- kind : `GeekHero`, pluriel `geekheroes`, singulier `geekhero`, nom court
  `gk` ;
- ressource rattachée à un namespace ;
- une seule version, `v1`, servie et stockée ;
- champs de `spec` :
  - `universe` : chaîne de caractères ;
  - `specialPower` : chaîne de caractères ;
  - `powerLevel` : entier compris entre `0` et `10000`.

Un `GeekHero` avec `powerLevel: 15000` doit être refusé par l'API.
`kubectl get gk -n ckad-crd-01` doit répondre sans erreur.
