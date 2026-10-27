#!/usr/bin/env bash
# Banc de test de bout en bout : k3s local UNIQUEMENT.
# Pour chaque exercice : lab.sh start, check (doit échouer avec rappels),
# solution sol-*.sh, check (doit réussir), lab.sh reset.
# Usage : ./harness.sh <id>...   (ou "all")
# Prérequis : ../../exos/ckad-workloads/init.sh pour les exercices ing-*.
set -u
SCRATCH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Kubeconfig dédié au k3s : jamais le contexte courant (clusters partagés).
export KUBECONFIG="${E2E_KUBECONFIG:-$HOME/.kube/k3s-only.yaml}"
server="$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')"
if [[ "$server" != "${E2E_SERVER:-https://127.0.0.1:6443}" ]]; then
  echo "ABANDON : serveur inattendu ($server)"; exit 3
fi
cd "$SCRATCH/../../exos/ckad-workloads" || exit 1
for f in "$SCRATCH"/sol-*.sh; do source "$f"; done
LOG="$SCRATCH/e2e-logs"; mkdir -p "$LOG"

ALL="pod-01 pod-02 pod-03 pod-04 pod-05 pod-06 pod-07 pod-08 pod-09 pod-10 pod-11 pod-12 pod-13
rs-01 rs-02 rs-03 deploy-01 deploy-02 deploy-03 deploy-04 deploy-05 deploy-06 deploy-07 deploy-08
ds-01 ds-02 ds-03 ds-04 sts-01 sts-02 sts-03 sts-04 sts-05
vol-01 vol-02 vol-03 vol-04 vol-05 vol-06 vol-07 vol-08
svc-01 svc-02 svc-03 svc-04 svc-05 svc-06 svc-07 svc-08 svc-09 svc-10 svc-11 svc-12
np-01 np-02 np-03 np-04 np-05 np-06 ing-01 ing-02 ing-03 ing-04 ing-05 ing-06
sec-01 sec-02 sec-03 sec-04 sec-05 sec-06 probe-01 probe-02 probe-03 probe-04 probe-05
res-01 res-02 res-03 res-04 res-05 sa-01 sa-02 sa-03 sa-04 sa-05
rbac-01 rbac-02 rbac-03 rbac-04 rbac-05 rbac-06 crd-01 crd-02 crd-03 crd-04 crd-05"
ids="$*"; [[ "$ids" == "all" ]] && ids="$ALL"

for id in $ids; do
  fn="${id//-/}"
  if ! declare -F "$fn" >/dev/null; then echo "$id SANS-SOLUTION"; continue; fi
  if ! ./lab.sh start "$id" >"$LOG/$id.start" 2>&1; then echo "$id START-KO"; continue; fi
  ./check.sh "$id" >"$LOG/$id.before" 2>&1; before=$?
  # le guidage doit apparaître en cas d'échec
  guided=1; grep -q "Rappel :" "$LOG/$id.before" && grep -q "Pour avancer" "$LOG/$id.before" && guided=0
  timeout 400 bash -c "source_all() { for f in '$SCRATCH'/sol-*.sh; do source \"\$f\"; done; }; source_all; $fn ckad-$id" >"$LOG/$id.sol" 2>&1
  after=1
  for _ in $(seq 1 30); do
    if ./check.sh "$id" >"$LOG/$id.after" 2>&1; then after=0; break; fi
    sleep 4
  done
  if [[ $before -ne 0 && $guided -eq 0 && $after -eq 0 ]]; then
    echo "$id OK"
  else
    echo "$id KO before=$before guided=$guided after=$after"
    sed 's/^/    /' "$LOG/$id.after"
  fi
  ./lab.sh reset "$id" >/dev/null 2>&1
done
