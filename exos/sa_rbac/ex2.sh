#!/bin/bash

# 1. Création du namespace right-ns
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: right-ns
EOF

# 2. Création du compte de service ex2sa
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ex2sa
  namespace: right-ns
EOF

# 5. Création d'un pod de test
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  namespace: right-ns
spec:
  containers:
  - name: test-container
    image: nginx
EOF


cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: selfsubjectaccessreviews-reader
rules:
  - apiGroups: ["authorization.k8s.io"]
    resources: ["selfsubjectaccessreviews"]
    verbs: ["get", "list", "watch"] # Permissions de lecture

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: mon-service-account-selfsubjectaccessreviews
subjects:
  - kind: ServiceAccount
    name: ex2sa
    namespace: default # Remplacez par votre namespace
roleRef:
  kind: ClusterRole
  name: selfsubjectaccessreviews-reader
  apiGroup: rbac.authorization.k8s.io
EOF



 6  export RESOURCE="pods"
    7  export VERB="get"
    8  export NAMEPASCED="true" 
    9  export NAMESPACE="right-ns"
 17  export RESOURCE="pods/log"
   18  export  VERB="get"