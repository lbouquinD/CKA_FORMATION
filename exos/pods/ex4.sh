#!/bin/bash  

RED="\e[31m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"

yaml=$(cat << EOF
apiVersion: v1
kind: Pod
metadata:
  name: pod1
spec:
  containers:
  - name: busybox
    image: busybox
    command: ["sh", "-c", "echo 'Bonjour  depuis le Pod1'; sleep 100000"]
EOF
)

# Apply the YAML using kubectl
kubectl apply -f - << EOF
$yaml
EOF

