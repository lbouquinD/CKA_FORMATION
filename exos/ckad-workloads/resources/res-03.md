# res-03 — LimitRange

Niveau 2 — 18 minutes

Contexte : namespace `ckad-res-03`.

Créez d'abord un LimitRange `defaults` de type `Container` :

- `max` : cpu `500m`, memory `256Mi` ;
- `min` : cpu `20m`, memory `32Mi` ;
- `default` : cpu `200m`, memory `128Mi` ;
- `defaultRequest` : cpu `50m`, memory `64Mi`.

Ensuite seulement, créez un Pod `plain`, conteneur `web`, image
`nginx:1.27.3`, sans bloc `resources`.

Le Pod doit être `Ready` et porter les requests et limits par défaut.
Un LimitRange ne réécrit pas un Pod déjà créé. `default` remplit les limits,
`defaultRequest` remplit les requests.
