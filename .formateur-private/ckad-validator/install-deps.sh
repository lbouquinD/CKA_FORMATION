#!/usr/bin/env bash
set -euo pipefail

GO_VERSION="${GO_VERSION:-1.26.7}"
INSTALL_DIR="${GO_INSTALL_DIR:-$HOME/.local/go}"

need_go() {
  if ! command -v go >/dev/null 2>&1; then
    return 0
  fi
  local current
  current="$(go env GOVERSION 2>/dev/null || true)"
  current="${current#go}"
  if [[ -z "$current" ]]; then
    return 0
  fi
  # Compare major.minor (ex. 1.26)
  local want_major want_minor have_major have_minor
  want_major="${GO_VERSION%%.*}"
  want_minor="$(echo "$GO_VERSION" | cut -d. -f2)"
  have_major="${current%%.*}"
  have_minor="$(echo "$current" | cut -d. -f2)"
  if (( have_major < want_major )) || { (( have_major == want_major )) && (( have_minor < want_minor )); }; then
    return 0
  fi
  return 1
}

arch="$(uname -m)"
case "$arch" in
  x86_64|amd64) go_arch="amd64" ;;
  aarch64|arm64) go_arch="arm64" ;;
  *)
    echo "Architecture non prise en charge : $arch" >&2
    exit 1
    ;;
esac

if need_go; then
  echo "Installation de Go ${GO_VERSION} dans ${INSTALL_DIR}"
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  archive="go${GO_VERSION}.linux-${go_arch}.tar.gz"
  curl -fsSL "https://go.dev/dl/${archive}" -o "${tmp}/${archive}"
  parent="$(dirname "$INSTALL_DIR")"
  mkdir -p "$parent"
  extract_dir="${tmp}/extract"
  mkdir -p "$extract_dir"
  tar -C "$extract_dir" -xzf "${tmp}/${archive}"
  rm -rf "$INSTALL_DIR"
  mv "${extract_dir}/go" "$INSTALL_DIR"
  export PATH="${INSTALL_DIR}/bin:${PATH}"
  echo "Ajoutez au PATH : export PATH=\"${INSTALL_DIR}/bin:\$PATH\""
else
  echo "Go déjà présent : $(go version)"
fi

echo "Installation de garble (obfuscation des binaires)"
GOBIN="${GOBIN:-$HOME/go/bin}"
mkdir -p "$GOBIN"
export PATH="$(go env GOPATH)/bin:${PATH}"
go install mvdan.cc/garble@latest
echo "garble : $(command -v garble)"

echo "Dépendances prêtes. Relancez votre shell ou exportez PATH si Go vient d'être installé."
