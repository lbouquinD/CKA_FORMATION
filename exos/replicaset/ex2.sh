#!/bin/bash  

RED="\e[31m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"

kubectl  delete rs --all  --grace-period=0 --force

yaml=$(cat << EOF
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: ex2replicaset
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ex2replicaset
  template:
    metadata:
      labels:
        app: ex2replicaset
    spec:
      containers:
      - name: premier-replicaset
        image: nginx:1.27.3

---
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: ex2replicaset2
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ex2replicaset2
  template:
    metadata:
      labels:
        app: ex2replicaset2
    spec:
      containers:
      - name: premier-replicaset
        image: nginx:1.27.3
---
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: testresplicatset
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ex2replicaset3
  template:
    metadata:
      labels:
        app: ex2replicaset3
    spec:
      containers:
      - name: premier-replicaset
        image: nginx:1.27.3
EOF
)

# Apply the YAML using kubectl
kubectl apply -f - << EOF
$yaml
EOF