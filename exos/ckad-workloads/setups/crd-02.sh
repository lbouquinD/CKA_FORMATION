#!/usr/bin/env bash
set -euo pipefail

kubectl wait --for=condition=Established crd/heroes.crd02.ckad.io --timeout=60s >/dev/null
kubectl apply -n "$EXERCISE_NAMESPACE" -f - <<'EOF'
apiVersion: crd02.ckad.io/v1
kind: Hero
metadata:
  name: saitama
spec:
  universe: Manga
  specialPower: One Punch
  powerLevel: 10000
EOF
