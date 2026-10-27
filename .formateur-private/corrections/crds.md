# Corrections — CustomResourceDefinitions

Fichier formateur. Ne pas ouvrir pendant la session stagiaire.

Le nom d'une CRD est `<pluriel>.<groupe>`. Les objets créés ont
l'`apiVersion` `<groupe>/<version>`. Le schéma `openAPIV3Schema` est
obligatoire en `apiextensions.k8s.io/v1`. Il valide les objets à
l'enregistrement. Un champ inconnu est refusé par `kubectl apply`, qui envoie la
validation `Strict`.

Outils : `kubectl api-resources --api-group=<groupe>`, `kubectl explain <kind>.spec`,
`kubectl get crd <nom> -o yaml`.

Supprimer une CRD supprime tous ses objets. `lab.sh reset` retire les CRD des
exercices.

---

## crd-01 — Définir une ressource

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: geekheroes.crd01.ckad.io
spec:
  group: crd01.ckad.io
  scope: Namespaced
  names:
    kind: GeekHero
    plural: geekheroes
    singular: geekhero
    shortNames: ["gk"]
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                universe:
                  type: string
                specialPower:
                  type: string
                powerLevel:
                  type: integer
                  minimum: 0
                  maximum: 10000
```

Test du refus :

```bash
cat <<'EOF' | kubectl apply -n ckad-crd-01 --dry-run=server -f -
apiVersion: crd01.ckad.io/v1
kind: GeekHero
metadata:
  name: saitama
spec:
  universe: Manga
  specialPower: One Punch
  powerLevel: 15000
EOF
# spec.powerLevel: Invalid value: 15000: ... should be less than or equal to 10000
```

---

## crd-02 — Utiliser une ressource personnalisée

```bash
kubectl api-resources --api-group=crd02.ckad.io   # heroes, hr, crd02.ckad.io/v1
kubectl explain hero.spec
```

```yaml
apiVersion: crd02.ckad.io/v1
kind: Hero
metadata:
  name: batman
spec:
  universe: Comics
  specialPower: Intellect & Martial Arts
  powerLevel: 85
---
apiVersion: crd02.ckad.io/v1
kind: Hero
metadata:
  name: gandalf
spec:
  universe: Fantasy
  specialPower: Magic
  powerLevel: 9000
---
apiVersion: crd02.ckad.io/v1
kind: Hero
metadata:
  name: goku
spec:
  universe: Manga
  specialPower: Super Saiyan
  powerLevel: 9500
```

```bash
kubectl apply -n ckad-crd-02 -f heroes.yaml
kubectl delete hr saitama -n ckad-crd-02
```

`metadata.name` doit être en minuscules : `Batman` est refusé.

---

## crd-03 — Faire évoluer une CRD

`kubectl edit crd backups.crd03.ckad.io`, dans `spec.versions[0]` :

```yaml
    - name: v1
      served: true
      storage: true
      additionalPrinterColumns:
        - name: Schedule
          type: string
          jsonPath: .spec.schedule
        - name: Retention
          type: integer
          jsonPath: .spec.retention
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                schedule:
                  type: string
                retention:
                  type: integer
                  minimum: 1
```

```yaml
apiVersion: crd03.ckad.io/v1
kind: Backup
metadata:
  name: nightly
spec:
  schedule: "0 2 * * *"
  retention: 7
```

Mettez des guillemets autour de `0 2 * * *` : sans eux, `*` est lu comme un
alias YAML.
Dès qu'une colonne est déclarée, `AGE` disparaît. Ajoutez une colonne
`.metadata.creationTimestamp` de type `date` pour le garder.

---

## crd-04 — Manifeste refusé

`kubectl apply` montre les erreurs une par une :

1. `no matches for kind "Widget" in version "crd04.ckad.io/v1beta1"` → la
   seule version servie est `v1` (`kubectl api-resources --api-group=crd04.ckad.io`) ;
2. une fois la version corrigée, l'API refuse `size` (chaîne au lieu d'un
   entier) → ôter les guillemets ;
3. puis le champ inconnu `colour` et le champ requis `color` manquant → le
   champ s'appelle `color` (`kubectl explain widget.spec`).

```yaml
apiVersion: crd04.ckad.io/v1
kind: Widget
metadata:
  name: banner
spec:
  size: 3
  color: blue
```

```bash
kubectl apply -n ckad-crd-04 -f /tmp/ckad-crd-04/widget.yaml
```

---

## crd-05 — Ressource de cluster

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: regions.crd05.ckad.io
spec:
  group: crd05.ckad.io
  scope: Cluster
  names:
    kind: Region
    plural: regions
    singular: region
    shortNames: ["rg"]
  versions:
    - name: v1
      served: true
      storage: true
      subresources:
        status: {}
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                code:
                  type: string
                  pattern: "^[a-z]{3}$"
            status:
              type: object
              x-kubernetes-preserve-unknown-fields: true
---
apiVersion: crd05.ckad.io/v1
kind: Region
metadata:
  name: eu-west
spec:
  code: euw
```

Avec la sous-ressource `status`, un `kubectl apply` ignore le champ `status`
de l'objet. Il s'écrit par `/status`, en général par un contrôleur.
