#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  echo "Usage: $0 {start|status|reset} <exercise-id>" >&2
  exit 2
}

is_valid_id() {
  case "$1" in
    pod-0[1-9]|pod-1[0-3]|rs-0[1-3]|deploy-0[1-8]|ds-0[1-4]|sts-0[1-5]|vol-0[1-8]) return 0 ;;
    *) return 1 ;;
  esac
}

[[ $# -eq 2 ]] || usage
action="$1"
exercise_id="$2"
is_valid_id "$exercise_id" || {
  echo "Identifiant d'exercice inconnu : $exercise_id" >&2
  exit 2
}

namespace="ckad-${exercise_id}"
setup_yaml="${ROOT_DIR}/setups/${exercise_id}.yaml"
setup_script="${ROOT_DIR}/setups/${exercise_id}.sh"

case "$action" in
  start)
    if kubectl get namespace "$namespace" >/dev/null 2>&1; then
      current_exercise="$(kubectl get namespace "$namespace" \
        -o jsonpath='{.metadata.labels.ckad\.training/exercise}')"
      if [[ "$current_exercise" != "$exercise_id" ]]; then
        echo "Refus de remplacer un namespace non créé par ce parcours." >&2
        exit 1
      fi
      kubectl delete namespace "$namespace" --wait=true >/dev/null
    fi
    kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -
    kubectl label namespace "$namespace" ckad.training/exercise="$exercise_id" --overwrite >/dev/null
    if [[ -f "$setup_yaml" ]]; then
      kubectl apply -n "$namespace" -f "$setup_yaml"
    fi
    if [[ -f "$setup_script" ]]; then
      EXERCISE_NAMESPACE="$namespace" bash "$setup_script"
    fi
    if [[ "$exercise_id" == "pod-13" ]]; then
      kubectl wait -n "$namespace" --for=condition=Ready pod/ops-reporter --timeout=120s
    fi
    echo "Exercice $exercise_id prêt dans le namespace $namespace."
    ;;
  status)
    kubectl get pods,services,deployments,replicasets,daemonsets,statefulsets,pvc,configmaps \
      -n "$namespace"
    ;;
  reset)
    kubectl delete namespace "$namespace" --ignore-not-found=true --wait=false
    rm -f "/tmp/ckad-${exercise_id}" "/tmp/ckad-${exercise_id}.txt" \
      "/tmp/ckad-${exercise_id}-labels.txt" "/tmp/ckad-${exercise_id}-ui.txt" \
      "/tmp/ckad-${exercise_id}.yaml"
    echo "Réinitialisation de $exercise_id demandée."
    ;;
  *)
    usage
    ;;
esac
