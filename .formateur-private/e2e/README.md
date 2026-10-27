# Tests de bout en bout du parcours

Fichier formateur. Rejoue chaque exercice sur un cluster de test :

1. `lab.sh start <id>` ;
2. `check.sh` doit échouer et afficher les rappels ;
3. la solution de `sol-*.sh` est appliquée ;
4. `check.sh` doit réussir (2 minutes au plus) ;
5. `lab.sh reset <id>`.

## Cluster

Uniquement un cluster jetable (k3s local). Le script n'utilise jamais le
contexte courant : il charge `~/.kube/k3s-only.yaml` et s'arrête si le serveur
n'est pas `https://127.0.0.1:6443`.

```bash
sudo cat /etc/rancher/k3s/k3s.yaml > ~/.kube/k3s-only.yaml && chmod 600 ~/.kube/k3s-only.yaml
```

`E2E_KUBECONFIG` et `E2E_SERVER` changent ces deux valeurs.

## Lancer

```bash
cd .formateur-private/e2e
KUBECONFIG=~/.kube/k3s-only.yaml ../../exos/ckad-workloads/init.sh   # une fois, pour ing-*
./harness.sh all            # environ 45 minutes
./harness.sh deploy-04 sec-06
```

Une ligne par exercice : `OK`, ou `KO before=… guided=… after=…` suivi de la
sortie du dernier check. Les journaux sont dans `e2e-logs/` (ignoré par git).

## Solutions

Une fonction par exercice, nommée sans tiret (`pod01`, `rbac06`), qui reçoit le
namespace en `$1`. Après un changement d'énoncé ou de validateur, adapter la
fonction et la correction dans `../corrections/`.
