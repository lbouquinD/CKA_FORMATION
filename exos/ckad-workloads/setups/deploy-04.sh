#!/usr/bin/env bash
set -euo pipefail

: "${EXERCISE_NAMESPACE:?}"

kubectl annotate deployment payments -n "$EXERCISE_NAMESPACE" \
  kubernetes.io/change-cause="stable release" --overwrite >/dev/null
kubectl set image deployment/payments payments=nginx:1.27.3 \
  -n "$EXERCISE_NAMESPACE" >/dev/null
kubectl rollout status deployment/payments -n "$EXERCISE_NAMESPACE" \
  --timeout=120s >/dev/null

kubectl annotate deployment payments -n "$EXERCISE_NAMESPACE" \
  kubernetes.io/change-cause="failed release" --overwrite >/dev/null
kubectl set image deployment/payments payments=nginx:does-not-exist \
  -n "$EXERCISE_NAMESPACE" >/dev/null
