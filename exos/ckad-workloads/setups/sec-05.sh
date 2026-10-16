#!/usr/bin/env bash
set -euo pipefail

if ! command -v openssl >/dev/null 2>&1; then
  echo "openssl est requis pour préparer le certificat de sec-05." >&2
  exit 1
fi

dir="/tmp/ckad-sec-05"
rm -rf "$dir"
mkdir -p "$dir"
openssl req -x509 -nodes -days 30 -newkey rsa:2048 \
  -keyout "${dir}/tls.key" -out "${dir}/tls.crt" \
  -subj "/CN=shop.ckad.local" >/dev/null 2>&1
chmod 644 "${dir}/tls.crt" "${dir}/tls.key"
echo "Certificat et clé prêts dans ${dir}."
