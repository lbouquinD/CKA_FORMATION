#!/usr/bin/env bash
set -euo pipefail

dir="/tmp/ckad-sec-02"
rm -rf "$dir"
mkdir -p "$dir"
printf '%s' 'appuser' > "${dir}/username"
printf '%s' 'file-secret-77' > "${dir}/password"
echo "Fichiers prêts dans ${dir}."
