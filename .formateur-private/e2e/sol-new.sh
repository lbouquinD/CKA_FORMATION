# Solutions des exercices sa/rbac/crd (reprises des corrections).
sa01() { kubectl create serviceaccount build-bot -n "$1"
  kubectl run builder -n "$1" --image=busybox:1.36 --overrides='{"spec":{"serviceAccountName":"build-bot"}}' -- sleep 3600; }
sa02() { kubectl apply -n "$1" -f - <<'EOF'
apiVersion: v1
kind: ServiceAccount
metadata:
  name: quiet-sa
automountServiceAccountToken: false
---
apiVersion: v1
kind: Pod
metadata:
  name: no-token
spec:
  serviceAccountName: quiet-sa
  containers:
    - name: app
      image: busybox:1.36
      command: ["sleep", "3600"]
EOF
}
sa03() { kubectl create serviceaccount ci -n "$1"
  kubectl create token ci -n "$1" --duration=2h > /tmp/ckad-sa-03.txt
  kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: ci-token
  namespace: ckad-sa-03
  annotations:
    kubernetes.io/service-account.name: ci
type: kubernetes.io/service-account-token
EOF
}
sa04() { kubectl create serviceaccount reporter-sa -n "$1"
  kubectl set serviceaccount deployment/reporter reporter-sa -n "$1"
  kubectl rollout status deployment/reporter -n "$1" --timeout=120s; }
sa05() { kubectl apply -n "$1" -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: audience-app
spec:
  serviceAccountName: api-client
  containers:
    - name: app
      image: busybox:1.36
      command: ["sleep", "3600"]
      volumeMounts:
        - name: vault-token
          mountPath: /var/run/secrets/vault
          readOnly: true
  volumes:
    - name: vault-token
      projected:
        sources:
          - serviceAccountToken:
              audience: vault
              expirationSeconds: 3600
              path: token
EOF
}
rbac01() { kubectl create serviceaccount viewer -n "$1"
  kubectl create role pod-reader -n "$1" --verb=get,list,watch --resource=pods
  kubectl create rolebinding pod-reader-binding -n "$1" --role=pod-reader --serviceaccount="$1":viewer; }
rbac02() { kubectl create serviceaccount deployer -n "$1"
  kubectl apply -n "$1" -f - <<'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployer
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "create", "update", "patch", "delete"]
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]
EOF
  kubectl create rolebinding deployer -n "$1" --role=deployer --serviceaccount="$1":deployer; }
rbac03() { kubectl create serviceaccount log-reader -n "$1"
  kubectl create clusterrole rbac-03-ns-lister --verb=list --resource=namespaces
  kubectl create clusterrolebinding rbac-03-ns-lister --clusterrole=rbac-03-ns-lister --serviceaccount="$1":log-reader
  kubectl apply -f - <<'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: log-reader
  namespace: ckad-rbac-03
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["list"]
  - apiGroups: [""]
    resources: ["pods/log"]
    verbs: ["get"]
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["create"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: log-reader
  namespace: ckad-rbac-03
subjects:
  - kind: ServiceAccount
    name: log-reader
    namespace: ckad-rbac-03
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: log-reader
EOF
}
rbac04() {
  kubectl -n "$1" patch role metrics-reader --type=json -p='[{"op":"replace","path":"/rules","value":[{"apiGroups":[""],"resources":["pods","services"],"verbs":["get","list","watch"]}]}]'
  kubectl -n "$1" patch rolebinding metrics-reader --type=json -p='[{"op":"replace","path":"/subjects/0/namespace","value":"ckad-rbac-04"}]'; }
rbac05() { kubectl create serviceaccount inventory -n "$1"
  kubectl create clusterrole rbac-05-node-viewer --verb=get,list --resource=nodes
  kubectl create clusterrolebinding rbac-05-node-viewer --clusterrole=rbac-05-node-viewer --serviceaccount="$1":inventory
  kubectl create rolebinding inventory-view -n "$1" --clusterrole=view --serviceaccount="$1":inventory; }
rbac06() { SA=system:serviceaccount:$1:auditor
  { kubectl auth can-i list pods -n "$1" --as=$SA
    kubectl auth can-i delete pods -n "$1" --as=$SA
    kubectl auth can-i get secrets -n "$1" --as=$SA
    kubectl auth can-i list secrets -n "$1" --as=$SA
    kubectl auth can-i list deployments.apps -n "$1" --as=$SA
    kubectl auth can-i list deployments.apps -n kube-system --as=$SA; } > /tmp/ckad-rbac-06.txt
  cat /tmp/ckad-rbac-06.txt; }
crd01() { kubectl apply -f - <<'EOF'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: geekheroes.crd01.ckad.io
spec:
  group: crd01.ckad.io
  scope: Namespaced
  names:
    kind: GeekHero
    plural: geekheroes
    singular: geekhero
    shortNames: ["gk"]
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                universe:
                  type: string
                specialPower:
                  type: string
                powerLevel:
                  type: integer
                  minimum: 0
                  maximum: 10000
EOF
}
crd02() { kubectl apply -n "$1" -f - <<'EOF'
apiVersion: crd02.ckad.io/v1
kind: Hero
metadata:
  name: batman
spec:
  universe: Comics
  specialPower: Intellect & Martial Arts
  powerLevel: 85
---
apiVersion: crd02.ckad.io/v1
kind: Hero
metadata:
  name: gandalf
spec:
  universe: Fantasy
  specialPower: Magic
  powerLevel: 9000
---
apiVersion: crd02.ckad.io/v1
kind: Hero
metadata:
  name: goku
spec:
  universe: Manga
  specialPower: Super Saiyan
  powerLevel: 9500
EOF
  kubectl delete hr saitama -n "$1"; }
crd03() { kubectl apply -f - <<'EOF'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: backups.crd03.ckad.io
spec:
  group: crd03.ckad.io
  scope: Namespaced
  names:
    kind: Backup
    plural: backups
    singular: backup
    shortNames: ["bk"]
  versions:
    - name: v1
      served: true
      storage: true
      additionalPrinterColumns:
        - name: Schedule
          type: string
          jsonPath: .spec.schedule
        - name: Retention
          type: integer
          jsonPath: .spec.retention
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                schedule:
                  type: string
                retention:
                  type: integer
                  minimum: 1
EOF
  sleep 2
  kubectl apply -n "$1" -f - <<'EOF'
apiVersion: crd03.ckad.io/v1
kind: Backup
metadata:
  name: nightly
spec:
  schedule: "0 2 * * *"
  retention: 7
EOF
  kubectl get bk -n "$1"; }
crd04() { echo "--- erreur attendue :"; kubectl apply -n "$1" -f /tmp/ckad-crd-04/widget.yaml
  sed -i -e 's#crd04.ckad.io/v1beta1#crd04.ckad.io/v1#' -e 's#size: "3"#size: 3#' -e 's#colour:#color:#' /tmp/ckad-crd-04/widget.yaml
  kubectl apply -n "$1" -f /tmp/ckad-crd-04/widget.yaml; }
crd05() { kubectl apply -f - <<'EOF'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: regions.crd05.ckad.io
spec:
  group: crd05.ckad.io
  scope: Cluster
  names:
    kind: Region
    plural: regions
    singular: region
    shortNames: ["rg"]
  versions:
    - name: v1
      served: true
      storage: true
      subresources:
        status: {}
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                code:
                  type: string
                  pattern: "^[a-z]{3}$"
            status:
              type: object
              x-kubernetes-preserve-unknown-fields: true
EOF
  kubectl wait --for=condition=Established crd/regions.crd05.ckad.io --timeout=60s
  kubectl apply -f - <<'EOF'
apiVersion: crd05.ckad.io/v1
kind: Region
metadata:
  name: eu-west
spec:
  code: euw
EOF
}

