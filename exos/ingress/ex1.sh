#!/bin/bash  

RED="\e[31m"
GREEN="\e[32m\1m"
ENDCOLOR="\e[0m"

yaml=$(cat << EOF
apiVersion: v1
kind: Namespace
metadata:
  name: exoingress
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: ex-ingress
  name: deploiement-ex-ingress-a
  namespace: exoingress
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ex-ingress
  template:
    metadata:
      labels:
        app: ex-ingress
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
    app: ex-ingress-b
  name: deploiement-ex-ingress-b
  namespace: exoingress
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ex-ingress-b
  template:
    metadata:
      labels:
        app: ex-ingress-b
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
apiVersion: v1
kind: Service
metadata:
  labels:
    app: ex-ingress
  name: svctoexpose-a
  namespace: exoingress
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 8124
  selector:
    app: ex-ingress-a
  type: ClusterIP
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: ex-ingress
  name: svctoexpose-b
  namespace: exoingress
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 8124
  selector:
    app: ex-ingress-b
  type: ClusterIP
EOF
)

# Apply the YAML using kubectl
kubectl apply -f - << EOF
$yaml
EOF


helm upgrade --install  -n exoingress ingress-nginx-controller nginx-ingress-controller/ 1>/dev/null

echo -e "${GREEN} script executé sans erreur ${ENDCOLOR}"