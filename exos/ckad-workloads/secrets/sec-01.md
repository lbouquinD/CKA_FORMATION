# sec-01 — Secret Opaque

Niveau 1 — 10 minutes

Contexte : namespace `ckad-sec-01`.

Créez un Secret `db-creds` de type Opaque :

- clé `username`, valeur `dbadmin` ;
- clé `password`, valeur `Ck4d-db-91`.

Les valeurs sont stockées encodées dans `data`. Cet encodage n'est pas un chiffrement.
