# pod-04 — Variables d'environnement et logs

Niveau 1

Contexte : namespace `ckad-pod-04`.

Créez un Pod nommé `box-check` basé sur l'image `busybox`, exécutant
`sh -c "env && sleep 3600"`.

Injectez les variables :

- `DB_HOST=postgres`;
- `DB_PORT=5432`.

Le Pod doit rester actif. Vérifiez les variables avec `kubectl logs`, sans
`kubectl exec`.
