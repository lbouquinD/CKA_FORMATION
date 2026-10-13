#!/usr/bin/env bash
set -euo pipefail

: "${EXERCISE_NAMESPACE:?}"

if ! command -v openssl >/dev/null 2>&1; then
  echo "openssl est requis pour préparer le Secret TLS de ing-05." >&2
  exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
openssl req -x509 -nodes -days 30 -newkey rsa:2048 \
  -keyout "${tmp}/tls.key" -out "${tmp}/tls.crt" \
  -subj "/CN=secure.ckad.local" >/dev/null 2>&1
kubectl create secret tls web-tls -n "$EXERCISE_NAMESPACE" \
  --cert="${tmp}/tls.crt" --key="${tmp}/tls.key" \
  --dry-run=client -o yaml | kubectl apply -f -
