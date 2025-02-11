#!/bin/bash  

RED="\e[31m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"

yaml=$(cat << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    toto: dep-ex-service-2
  name: dep-ex-service-2
spec:
  replicas: 1
  selector:
    matchLabels:
      toto: dep-ex-service-2
  template:
    metadata:
      labels:
        toto: dep-ex-service-2
    spec:
      containers:
      - image: laurentsogeti/ckad_formation_networkpolicies:0.0.1
        name: ckad-formation-service-pw8gd
        env: 
          - name: LISTENPORT
            value: "8124"
          - name:  URL
            value: dep-ex-service-2
          - name:  NOMAPP
            value: dep-ex-service-2

---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    toto: dep-ex-service-3
  name: dep-ex-service-3
spec:
  replicas: 1
  selector:
    matchLabels:
      truc: dep-ex-service-3
  template:
    metadata:
      labels:
        truc: dep-ex-service-3
    spec:
      containers:
      - image: laurentsogeti/ckad_formation_networkpolicies:0.0.1
        name: ckad-formation-service-pw8gd
        env: 
          - name: LISTENPORT
            value: "9090"
          - name:  URL
            value: dep-ex-service-3
          - name:  NOMAPP
            value: dep-ex-service-3

EOF
)

# Apply the YAML using kubectl
kubectl apply -f - << EOF
$yaml
EOF