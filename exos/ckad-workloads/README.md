# Parcours intensif CKAD — Workloads

Ce parcours contient 65 exercices pratiques, rédigés comme des tâches d'examen.
Chaque exercice utilise son propre namespace afin de pouvoir être joué indépendamment.

## Mode d'emploi

```bash
cd exos/ckad-workloads
bash ../init-Killercoda.sh
./init.sh   # une fois par cluster, avant les exercices ingress
./lab.sh start pod-01
# Lire pods/pod-01.md puis réaliser la tâche
./check.sh pod-01
./lab.sh status pod-01
./lab.sh reset pod-01
```

Le validateur affiche les catégories réussies ou à revoir. En cas d'échec, il
ajoute un court rappel de cours, sans donner la valeur attendue ni la commande
à recopier. Un code de sortie `0` signifie que l'exercice est réussi.

## Parcours

| Thème | Exercices | Durée indicative |
|---|---:|---:|
| Pods | `pod-01` à `pod-13` | 3 h |
| ReplicaSets | `rs-01` à `rs-03` | 50 min |
| Deployments | `deploy-01` à `deploy-08` | 2 h 45 |
| DaemonSets | `ds-01` à `ds-04` | 1 h 15 |
| StatefulSets | `sts-01` à `sts-05` | 2 h |
| Volumes / PVC | `vol-01` à `vol-08` | 2 h 20 |
| Services | `svc-01` à `svc-12` | 2 h 50 |
| NetworkPolicies | `np-01` à `np-06` | 2 h |
| Ingress | `ing-01` à `ing-06` | 2 h |

## Règles proches de l'examen

- Travaillez uniquement dans le namespace indiqué.
- Vous pouvez utiliser la documentation Kubernetes.
- Évitez de consulter le validateur : son résultat suffit pour vous orienter.
- Vérifiez toujours le contexte courant avant d'agir.
- Privilégiez les commandes impératives avec `--dry-run=client -o yaml` lorsque cela
  fait gagner du temps, puis éditez le YAML généré.
- Les fichiers demandés doivent respecter exactement le chemin indiqué.
- Avant les exercices Ingress, lancez une fois `./init.sh`. Il installe le
  contrôleur dont la classe s'appelle `ckad`.
- Ce contrôleur refuse deux Ingress qui publient le même hôte et le même
  chemin, y compris dans des namespaces différents. Chaque exercice utilise
  un hôte distinct.
- Les NetworkPolicies sont corrigées sur l'objet déclaré. Selon le CNI du
  cluster, les paquets ne sont pas forcément bloqués : le validateur juge la
  politique, pas un test de connectivité.

## Niveaux

- Niveau 1 : création et commandes fondamentales.
- Niveau 2 : composition, exploitation et mises à jour.
- Niveau 3 : diagnostic d'une ressource existante ou scénario multi-ressources.

`lab.sh reset <id>` ne supprime que le namespace de l'exercice concerné et les
fichiers temporaires associés.

Relancer `lab.sh start <id>` remet volontairement cet exercice à zéro après
avoir vérifié que son namespace appartient bien au parcours.

## Formateur

Les corrections (commandes + explications) sont dans
[`.formateur-private/corrections/`](../../.formateur-private/corrections/).

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
