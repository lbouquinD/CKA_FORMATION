# Corrections — CKAD Workloads

Fichier formateur. Ne pas ouvrir pendant la session stagiaire.

Les commandes ci-dessous sont des solutions types. D'autres formulations
équivalentes sont valides tant que l'état du cluster correspond aux critères.

---

## pod-01 — Création impérative

Objectif : un seul `kubectl run`.

```bash
kubectl run web-dev -n ckad-pod-01 --image=nginx:alpine \
  --labels=tier=frontend --env=APP_ENV=development
```

- `--labels` pose `tier=frontend` à la création.
- `--env` injecte `APP_ENV` dans le conteneur (nommé `web-dev` par défaut).
- Pas de YAML local : tout est dans la commande.

---

## pod-02 — Labels et annotations à chaud

Le Pod est déjà là (`./lab.sh start pod-02`). On ne le recrée pas.

```bash
kubectl annotate pod web-dev -n ckad-pod-02 builder=ansible
kubectl label pod web-dev -n ckad-pod-02 tier=ui --overwrite
kubectl label pod web-dev -n ckad-pod-02 stage=test
```

- `annotate` n'exige pas `--overwrite` si la clé n'existe pas encore.
- `label ... --overwrite` est obligatoire pour changer `tier` : Kubernetes refuse
  sinon de remplacer une clé déjà présente.
- Ces opérations ne redémarrent pas le Pod.

---

## pod-03 — Inspection, filtrage, YAML propre

Le namespace contient `web-dev` (`tier=ui`) et `api-dev` (`tier=backend`).

```bash
kubectl get po -n ckad-pod-03 --show-labels > /tmp/ckad-pod-03-labels.txt
kubectl get po -n ckad-pod-03 -l tier=ui > /tmp/ckad-pod-03-ui.txt
kubectl run web-dev --image=nginx:alpine --restart=Never \
  --labels=tier=ui,stage=test --env=APP_ENV=development \
  --dry-run=client -o yaml > /tmp/ckad-pod-03.yaml
```

- `--show-labels` ajoute la colonne LABELS.
- `-l tier=ui` filtre côté API : `api-dev` ne doit pas apparaître.
- `kubectl get -o yaml` contient `uid` et `resourceVersion` : inutilisable tel
  quel pour recréer. `--dry-run=client -o yaml` produit un manifeste propre.

On peut aussi annoter le run pour coller au Pod réel (`builder=ansible`), ce
n'est pas exigé par le validateur.

---

## pod-04 — Env + logs

```bash
kubectl run box-check -n ckad-pod-04 --image=busybox \
  --env=DB_HOST=postgres --env=DB_PORT=5432 \
  --command -- sh -c "env && sleep 3600"
kubectl logs -n ckad-pod-04 box-check
```

- `--command` indique que ce qui suit `--` remplace l'entrypoint.
- `env && sleep 3600` affiche les variables **dans stdout**, donc dans
  `kubectl logs`. Pas besoin de `exec`.
- Attendre que le Pod soit Running avant de lire les logs.

---

## pod-05 — Suppression par label et force

Présents au départ : `web-dev` et `cache-dev` (`stage=test`), plus `box-check`.

```bash
kubectl delete po -n ckad-pod-05 -l stage=test
kubectl delete po box-check -n ckad-pod-05 --force --grace-period=0
```

- `-l` supprime toutes les ressources du sélecteur, pas une par une.
- `--force --grace-period=0` retire l'entrée API tout de suite (le processus
  peut encore mourir côté nœud). À l'examen on l'utilise quand l'énoncé le
  demande, pas par habitude.

---

## pod-06 — Création rapide (nginx)

```bash
kubectl run web-fast -n ckad-pod-06 --image=nginx:1.27.3 --labels=app=web-fast
# le conteneur s'appelle web-fast : le renommer en nginx si besoin
kubectl run web-fast -n ckad-pod-06 --image=nginx:1.27.3 --labels=app=web-fast \
  --dry-run=client -o yaml | sed 's/name: web-fast/name: nginx/' | kubectl apply -f -
```

Le validateur exige le **conteneur** `nginx`. Un `kubectl run` brut nomme le
conteneur comme le Pod : générer le YAML et corriger `spec.containers[0].name`.

---

## pod-07 — Métadonnées et ressources

```bash
kubectl run api-limited -n ckad-pod-07 --image=nginx:1.27.3 --dry-run=client -o yaml > /tmp/p.yaml
# éditer : container name api, labels, annotation, requests/limits
kubectl apply -n ckad-pod-07 -f /tmp/p.yaml
```

Champs attendus : `app=api`, `tier=backend`,
`training.ckad/owner=team-blue`, requests `50m/32Mi`, limits `100m/64Mi`.

---

## pod-08 — Sidecar

Manifeste à deux conteneurs `writer` / `reader`, `emptyDir` `shared-logs`
monté sur `/var/log/shared`. Writer : boucle `date >> .../app.log ; sleep 5`.
Reader : `tail -F`.

---

## pod-09 — Init container

Init `prepare` écrit `/work/index.html` (`CKAD initialized`) sur le volume
`web-content`. Conteneur `web` (`nginx:1.27.3`) monte le volume sur
`/usr/share/nginx/html`.

---

## pod-10 — Sondes

Le setup a des probes vers `/not-ready` et le port `8080`. Corriger path `/`,
port `80`, `initialDelaySeconds: 2`. Recréer le Pod si besoin (spec immuable
selon les champs).

---

## pod-11 — CrashLoopBackOff

La commande du setup sort tout de suite. Remplacer par `sleep 3600`, image
`busybox:1.36`, conteneur `worker`. Recréer le Pod.

---

## pod-12 — Image et Downward API

Image `busybox:1.36`, `sh -c` + sleep, `APP_MODE=production`,
`POD_NAME` via `fieldRef: metadata.name`.

---

## pod-13 — Logs, inventaire, delete

```bash
kubectl logs -n ckad-pod-13 ops-reporter -c reporter > /tmp/ckad-pod-13
kubectl get po -n ckad-pod-13 --sort-by=.metadata.name \
  -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.spec.containers[0].image}{" "}{.status.phase}{"\n"}{end}' \
  > /tmp/ckad-pod-13.txt
kubectl delete po obsolete-pod -n ckad-pod-13
```

Exporter **avant** de supprimer `obsolete-pod`.
