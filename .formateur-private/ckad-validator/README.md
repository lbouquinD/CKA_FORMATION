# Validateur CKAD Workloads

Sources du binaire appelé par `exos/ckad-workloads/check.sh`.

Les stagiaires n'ont pas besoin d'ouvrir ce dossier. Les énoncés et
`./check.sh <id>` suffisent pour la session.

## Prérequis (Linux / WSL)

- `curl`, `tar`, `sha256sum`
- Go 1.26 ou plus récent
- `garble` (recommandé) pour obfusquer les chaînes du binaire

Installation automatique :

```bash
cd .formateur-private/ckad-validator
chmod +x install-deps.sh build.sh
./install-deps.sh
# si Go vient d'être installé dans ~/.local/go :
export PATH="$HOME/.local/go/bin:$(go env GOPATH 2>/dev/null || echo "$HOME/go")/bin:$PATH"
```

Installation manuelle :

```bash
# Go officiel
curl -fsSL https://go.dev/dl/go1.26.7.linux-amd64.tar.gz -o /tmp/go.tgz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf /tmp/go.tgz
export PATH="/usr/local/go/bin:$PATH"

# Obfuscateur
go install mvdan.cc/garble@latest
export PATH="$(go env GOPATH)/bin:$PATH"
```

Sur Debian/Ubuntu, `apt install golang-go` en 1.22 suffit pour ce module.

## Compiler les binaires

```bash
cd .formateur-private/ckad-validator
./build.sh
```

Le script :

1. lance `go test ./...` ;
2. compile `linux/amd64` et `linux/arm64` (avec `garble` s'il est dans le PATH) ;
3. écrit les fichiers dans `exos/ckad-workloads/bin/` ;
4. met à jour `exos/ckad-workloads/bin/SHA256SUMS`.

Sans `garble`, la compilation fonctionne quand même, mais les valeurs de
contrôle restent plus lisibles dans le binaire.

## Après une modification des exercices

1. Adapter `main.go` si un critère de validation change.
2. Relancer `./build.sh`.
3. Tester sur un cluster Linux : `cd exos/ckad-workloads && ./lab.sh start pod-01 && ./check.sh pod-01`.
