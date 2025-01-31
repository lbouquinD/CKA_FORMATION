#!/bin/bash

yaml=$(cat << EOF
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: ledemon
  labels:
    k8s-app: fluentd-logging
spec:
  selector:
    matchLabels:
      name: ledemon
  template:
    metadata:
      labels:
        name: ledemon
    spec:
      containers:
      - name: conteneur1
        image: nginx:1.27.3
      terminationGracePeriodSeconds: 30
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: toto
  labels:
    k8s-app: fluentd-logging
spec:
  selector:
    matchLabels:
      name: toto
  template:
    metadata:
      labels:
        name: toto
    spec:
      containers:
      - name: conteneur1
        image: nginx:1.27.3
      terminationGracePeriodSeconds: 30
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: unautre-demon
  labels:
    k8s-app: fluentd-logging
spec:
  selector:
    matchLabels:
      name: unautre-demon
  template:
    metadata:
      labels:
        name: unautre-demon
    spec:
      containers:
      - name: conteneur1
        image: nginx:1.27.3
      terminationGracePeriodSeconds: 30
EOF
)

# Apply the YAML using kubectl with --record
kubectl apply -f - << EOF
$yaml
EOF



