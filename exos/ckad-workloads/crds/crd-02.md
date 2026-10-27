# crd-02 — Utiliser une ressource personnalisée

Niveau 1 — 12 minutes

Contexte : namespace `ckad-crd-02`.

Préparez le scénario avec `./lab.sh start crd-02`. Une CRD décrit la ressource
`Hero`. Retrouvez son groupe, sa version et ses champs.

Créez ces trois objets `Hero` dans le namespace :

| Nom | universe | specialPower | powerLevel |
|---|---|---|---:|
| `batman` | `Comics` | `Intellect & Martial Arts` | 85 |
| `gandalf` | `Fantasy` | `Magic` | 9000 |
| `goku` | `Manga` | `Super Saiyan` | 9500 |

Supprimez ensuite le héros `saitama`.
