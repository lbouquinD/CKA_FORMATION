#!/bin/bash


kubectl delete deployment dep4  --force --grace-period=0 2>/dev/null 
yaml=$(cat << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dep1
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: conteneur1
        image: nginx:42.14.2
        ports:
        - containerPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dep2
  labels:
    app: dep2
spec:
  replicas: 3
  selector:
    matchLabels:
      app: dep2
  template:
    metadata:
      labels:
        app: dep2
    spec:
      containers:
      - name: conteneur1
        image: nginx:1.14.2
        ports:
        - containerPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dep3
  labels:
    app: dep3
spec:
  replicas: 3
  selector:
    matchLabels:
      app: dep3
  template:
    metadata:
      labels:
        app: dep3
    spec:
      containers:
      - name: conteneur1
        image: laurentsogeti/pod_showname_formation_ckad:0.0.2
        ports:
        - containerPort: 80
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dep4
  labels:
    app: dep4
spec:
  revisionHistoryLimit: 100
  replicas: 3
  selector:
    matchLabels:
      app: dep4
  template:
    metadata:
      labels:
        app: dep4
    spec:
      containers:
      - name: conteneur1
        image: nginx:1.14.3
        ports:
        - containerPort: 80
EOF
)

# Apply the YAML using kubectl with --record
kubectl apply -f - << EOF
$yaml
EOF
kubectl get rs -l app=dep4 -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' > /tmp/ex2Deployrsinit
kubectl set image deployment/dep4 conteneur1=nginx:1.14.1
kubectl set image deployment/dep4 conteneur1=nginx:1.14.2


