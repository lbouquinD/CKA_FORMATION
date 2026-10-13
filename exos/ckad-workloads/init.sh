#!/usr/bin/env bash
set -euo pipefail

# Installe ingress-nginx et l'IngressClass `ckad`, partagée par tous les
# exercices Ingress. L'exécution est idempotente.

INGRESS_VERSION="${INGRESS_VERSION:-controller-v1.12.1}"
MANIFEST_URL="https://raw.githubusercontent.com/kubernetes/ingress-nginx/${INGRESS_VERSION}/deploy/static/provider/cloud/deploy.yaml"
NS="ingress-nginx"
DEPLOY="ingress-nginx-controller"

if kubectl -n "$NS" get "deployment/${DEPLOY}" >/dev/null 2>&1; then
  echo "Contrôleur ingress-nginx déjà installé."
else
  echo "Installation d'ingress-nginx (${INGRESS_VERSION})"
  kubectl apply -f "$MANIFEST_URL"
  kubectl -n "$NS" wait --for=condition=complete job/ingress-nginx-admission-create --timeout=180s || true
  kubectl -n "$NS" wait --for=condition=complete job/ingress-nginx-admission-patch --timeout=180s || true
fi

echo "Attente du contrôleur"
kubectl -n "$NS" rollout status "deployment/${DEPLOY}" --timeout=300s

patch_ingress_class_arg() {
  local found
  found="$(kubectl -n "$NS" get "deployment/${DEPLOY}" -o go-template='{{range $i, $arg := (index .spec.template.spec.containers 0).args}}{{if or (eq $arg "--ingress-class=nginx") (eq $arg "--ingress-class=ckad")}}{{$i}} {{$arg}}{{"\n"}}{{end}}{{end}}')"
  if [[ -z "$found" ]]; then
    echo "Argument --ingress-class introuvable sur ${DEPLOY}." >&2
    return 1
  fi
  local index="${found%% *}"
  local value="${found#* }"
  value="${value//$'\n'/}"
  if [[ "$value" != "--ingress-class=ckad" ]]; then
    kubectl -n "$NS" patch "deployment/${DEPLOY}" --type=json \
      -p="[{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/0/args/${index}\",\"value\":\"--ingress-class=ckad\"}]"
  fi
}

patch_ingress_class_arg
kubectl -n "$NS" rollout status "deployment/${DEPLOY}" --timeout=300s

kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: ckad
  labels:
    ckad.training/component: ingress
spec:
  controller: k8s.io/ingress-nginx
EOF

echo "IngressClass ckad prête."
kubectl get ingressclass ckad
