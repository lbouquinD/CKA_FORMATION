#!/usr/bin/env bash
set -euo pipefail

kubectl wait --for=condition=Established crd/widgets.crd04.ckad.io --timeout=60s >/dev/null
dir="/tmp/ckad-crd-04"
rm -rf "$dir"
mkdir -p "$dir"
cat > "${dir}/widget.yaml" <<'EOF'
apiVersion: crd04.ckad.io/v1beta1
kind: Widget
metadata:
  name: banner
spec:
  size: "3"
  colour: blue
EOF
echo "Manifeste prêt : ${dir}/widget.yaml"
