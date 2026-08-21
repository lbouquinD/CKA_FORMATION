#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <exercise-id>" >&2
  exit 2
fi

case "$(uname -m)" in
  x86_64|amd64) validator="${ROOT_DIR}/bin/ckad-check-linux-amd64" ;;
  aarch64|arm64) validator="${ROOT_DIR}/bin/ckad-check-linux-arm64" ;;
  *)
    echo "Architecture non prise en charge : $(uname -m)" >&2
    exit 2
    ;;
esac

if [[ ! -f "$validator" ]]; then
  echo "Validateur absent pour cette architecture." >&2
  exit 2
fi

chmod u+x "$validator"
exec "$validator" check "$1"
