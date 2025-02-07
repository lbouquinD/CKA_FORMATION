 lignes=(
  "source <(kubectl completion bash)"
  "source /etc/bash_completion"
  "alias k=kubectl"
  "complete -o default -F __start_kubectl k"
)

for ligne in "${lignes[@]}"; do
  if ! grep -q "$ligne" ~/.bashrc; then
    sed -i "$ a $ligne" ~/.bashrc
  fi
done
source ~/.bashrc


kubectl get po 