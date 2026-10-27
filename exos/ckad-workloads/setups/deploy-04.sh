#!/usr/bin/env bash
set -euo pipefail

: "${EXERCISE_NAMESPACE:?}"

# change-cause est recopié sur le ReplicaSet le plus récent : on annote après
# chaque changement d'image, une fois la nouvelle révision créée.
kubectl rollout status deployment/payments -n "$EXERCISE_NAMESPACE" \
  --timeout=120s >/dev/null
kubectl set image deployment/payments payments=nginx:1.27.3 \
  -n "$EXERCISE_NAMESPACE" >/dev/null
kubectl rollout status deployment/payments -n "$EXERCISE_NAMESPACE" \
  --timeout=120s >/dev/null
kubectl annotate deployment payments -n "$EXERCISE_NAMESPACE" \
  kubernetes.io/change-cause="stable release" --overwrite >/dev/null

kubectl set image deployment/payments payments=nginx:does-not-exist \
  -n "$EXERCISE_NAMESPACE" >/dev/null
for _ in $(seq 1 30); do
  revision="$(kubectl get deployment payments -n "$EXERCISE_NAMESPACE" \
    -o jsonpath='{.metadata.annotations.deployment\.kubernetes\.io/revision}')"
  [[ "$revision" == "3" ]] && break
  sleep 1
done
kubectl annotate deployment payments -n "$EXERCISE_NAMESPACE" \
  kubernetes.io/change-cause="failed release" --overwrite >/dev/null
