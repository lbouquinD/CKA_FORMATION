# Parcours intensif CKAD — Workloads

Ce parcours contient 28 exercices pratiques, rédigés comme des tâches d'examen.
Chaque exercice utilise son propre namespace afin de pouvoir être joué indépendamment.

## Mode d'emploi

```bash
cd exos/ckad-workloads
bash ../init-Killercoda.sh
./lab.sh start pod-01
# Lire pods/pod-01.md puis réaliser la tâche
./check.sh pod-01
./lab.sh status pod-01
./lab.sh reset pod-01
```

Le validateur affiche uniquement les catégories réussies ou à revoir. Il ne donne ni
la commande attendue, ni la valeur correcte. Un code de sortie `0` signifie que
l'exercice est réussi.

## Parcours

| Thème | Exercices | Durée indicative |
|---|---:|---:|
| Pods | `pod-01` à `pod-08` | 2 h 15 |
| ReplicaSets | `rs-01` à `rs-03` | 50 min |
| Deployments | `deploy-01` à `deploy-08` | 2 h 45 |
| DaemonSets | `ds-01` à `ds-04` | 1 h 15 |
| StatefulSets | `sts-01` à `sts-05` | 2 h |

## Règles proches de l'examen

- Travaillez uniquement dans le namespace indiqué.
- Vous pouvez utiliser la documentation Kubernetes.
- Évitez de consulter le validateur : son résultat suffit pour vous orienter.
- Vérifiez toujours le contexte courant avant d'agir.
- Privilégiez les commandes impératives avec `--dry-run=client -o yaml` lorsque cela
  fait gagner du temps, puis éditez le YAML généré.
- Les fichiers demandés doivent respecter exactement le chemin indiqué.

## Niveaux

- Niveau 1 : création et commandes fondamentales.
- Niveau 2 : composition, exploitation et mises à jour.
- Niveau 3 : diagnostic d'une ressource existante ou scénario multi-ressources.

`lab.sh reset <id>` ne supprime que le namespace de l'exercice concerné et les
fichiers temporaires associés.

Relancer `lab.sh start <id>` remet volontairement cet exercice à zéro après
avoir vérifié que son namespace appartient bien au parcours.

## Formateur

Les sources du validateur sont dans `.formateur-private/ckad-validator/`.
Ne pas les ouvrir pendant la session : le but est de travailler comme à
l'examen, avec l'énoncé et `./check.sh`.

Pour reconstruire les binaires sous Linux / WSL :

```bash
cd .formateur-private/ckad-validator
chmod +x install-deps.sh build.sh
./install-deps.sh
export PATH="$HOME/.local/go/bin:$HOME/go/bin:$PATH"
./build.sh
```

Le détail est dans [`.formateur-private/ckad-validator/README.md`](../../.formateur-private/ckad-validator/README.md).
