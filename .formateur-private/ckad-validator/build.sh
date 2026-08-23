#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$(cd "$ROOT/../../exos/ckad-workloads/bin" && pwd)"
cd "$ROOT"

if ! command -v go >/dev/null 2>&1; then
  echo "Go est introuvable. Exécutez d'abord ./install-deps.sh" >&2
  exit 1
fi

export CGO_ENABLED=0
export GOTOOLCHAIN="${GOTOOLCHAIN:-local}"
export PATH="$(go env GOPATH)/bin:${PATH}"
export GOFLAGS="${GOFLAGS:-} -buildvcs=false"

echo "Tests unitaires"
go test ./...

build_one() {
  local arch="$1"
  local out="$2"
  export GOOS=linux
  export GOARCH="$arch"
  if command -v garble >/dev/null 2>&1; then
    echo "Compilation obfusquée linux/${arch}"
    garble -literals -tiny build -trimpath -ldflags="-s -w" -o "$out" .
  else
    echo "Compilation linux/${arch} (garble absent, binaire non obfusqué)"
    go build -trimpath -buildvcs=false -ldflags="-s -w" -o "$out" .
  fi
  chmod 0755 "$out"
}

build_one amd64 "${BIN_DIR}/ckad-check-linux-amd64"
build_one arm64 "${BIN_DIR}/ckad-check-linux-arm64"

(
  cd "$BIN_DIR"
  sha256sum ckad-check-linux-amd64 ckad-check-linux-arm64 > SHA256SUMS
)

echo "Binaires générés :"
ls -l "${BIN_DIR}/ckad-check-linux-"*
echo "Empreintes :"
cat "${BIN_DIR}/SHA256SUMS"
