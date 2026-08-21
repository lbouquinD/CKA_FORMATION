#!/usr/bin/env bash
set -euo pipefail

: "${EXERCISE_NAMESPACE:?}"

kubectl wait -n "$EXERCISE_NAMESPACE" --for=condition=Ready pod \
  -l app=worker --timeout=120s >/dev/null
initial_pods="$(kubectl get pods -n "$EXERCISE_NAMESPACE" -l app=worker \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | sort)"
kubectl create configmap rs03-baseline -n "$EXERCISE_NAMESPACE" \
  --from-literal=pods="$initial_pods" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
