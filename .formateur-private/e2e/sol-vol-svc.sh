# Solutions for vol-01..vol-08 and svc-01..svc-12.
# This file only defines functions; it is meant to be sourced.
# Each function receives the namespace as $1 (ckad-<id>).

# ---------------------------------------------------------------- volumes

vol01() {
  local ns="$1"
  kubectl apply -n "$ns" -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: scratch-box
  labels:
    app: scratch
spec:
  containers:
    - name: box
      image: busybox:1.36
      command: ["sleep", "3600"]
      volumeMounts:
        - name: scratch
          mountPath: /scratch
  volumes:
    - name: scratch
      emptyDir: {}
EOF
  kubectl wait -n "$ns" --for=condition=Ready pod/scratch-box --timeout=120s
  kubectl exec -n "$ns" scratch-box -c box -- sh -c 'echo CKAD-VOL > /scratch/ready.txt'
}

vol02() {
  local ns="$1"
  kubectl apply -n "$ns" -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: ram-box
  labels:
    app: ram
spec:
  containers:
    - name: box
      image: busybox:1.36
      command: ["sleep", "3600"]
      volumeMounts:
        - name: cache
          mountPath: /cache
  volumes:
    - name: cache
      emptyDir:
        medium: Memory
        sizeLimit: 32Mi
EOF
  kubectl wait -n "$ns" --for=condition=Ready pod/ram-box --timeout=120s
  kubectl exec -n "$ns" ram-box -c box -- sh -c 'echo CKAD-RAM > /cache/ready.txt'
}

vol03() {
  local ns="$1"
  kubectl apply -n "$ns" -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: share-html
  labels:
    app: share-html
spec:
  replicas: 1
  selector:
    matchLabels:
      app: share-html
  template:
    metadata:
      labels:
        app: share-html
    spec:
      containers:
        - name: loader
          image: busybox:1.36
          command: ["sh", "-c", "echo 'CKAD shared volume' > /work/index.html; sleep 3600"]
          volumeMounts:
            - name: html
              mountPath: /work
        - name: web
          image: nginx:1.27.3
          ports:
            - containerPort: 80
          volumeMounts:
            - name: html
              mountPath: /usr/share/nginx/html
      volumes:
        - name: html
          emptyDir: {}
EOF
  kubectl rollout status -n "$ns" deployment/share-html --timeout=150s
}

vol04() {
  local ns="$1"
  kubectl apply -n "$ns" -f - <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Mi
  storageClassName: local-path
---
apiVersion: v1
kind: Pod
metadata:
  name: app-storage
  labels:
    app: storage
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sleep", "3600"]
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: app-data
EOF
  kubectl wait -n "$ns" --for=condition=Ready pod/app-storage --timeout=150s
}

_vol05_pod() {
  kubectl apply -n "$1" -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: keep-pod
  labels:
    app: keep
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sleep", "3600"]
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: keep-data
EOF
}

vol05() {
  local ns="$1"
  kubectl apply -n "$ns" -f - <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: keep-data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
  storageClassName: local-path
EOF
  _vol05_pod "$ns"
  kubectl wait -n "$ns" --for=condition=Ready pod/keep-pod --timeout=120s
  kubectl exec -n "$ns" keep-pod -c app -- sh -c 'echo persisted > /data/marker'
  # Delete and recreate the Pod on the same PVC (sleep ignores SIGTERM: short grace).
  kubectl delete pod keep-pod -n "$ns" --grace-period=1 --wait=true --timeout=60s
  _vol05_pod "$ns"
  kubectl wait -n "$ns" --for=condition=Ready pod/keep-pod --timeout=120s
  kubectl exec -n "$ns" keep-pod -c app -- cat /data/marker
}

vol06() {
  local ns="$1"
  kubectl apply -n "$ns" -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: config-reader
  labels:
    app: config
spec:
  containers:
    - name: reader
      image: busybox:1.36
      command: ["sleep", "3600"]
      volumeMounts:
        - name: config
          mountPath: /etc/app
  volumes:
    - name: config
      configMap:
        name: app-config
EOF
  kubectl wait -n "$ns" --for=condition=Ready pod/config-reader --timeout=120s
}

vol07() {
  local ns="$1"
  # storageClassName is immutable: remove the Pod, then the PVC, then recreate both.
  kubectl delete pod data-writer -n "$ns" --grace-period=1 --wait=true --timeout=60s --ignore-not-found
  kubectl delete pvc broken-data -n "$ns" --wait=true --timeout=60s --ignore-not-found
  kubectl apply -n "$ns" -f - <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: broken-data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
  storageClassName: local-path
---
apiVersion: v1
kind: Pod
metadata:
  name: data-writer
  labels:
    app: writer
spec:
  containers:
    - name: writer
      image: busybox:1.36
      command: ["sleep", "3600"]
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: broken-data
EOF
  kubectl wait -n "$ns" --for=condition=Ready pod/data-writer --timeout=150s
  kubectl exec -n "$ns" data-writer -c writer -- sh -c 'echo fixed > /data/ok'
}

vol08() {
  local ns="$1"
  # An init container writes index.html into the PVC before nginx starts
  # (robust alternative to kubectl exec, as suggested in the correction).
  kubectl apply -n "$ns" -f - <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: web-content
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Mi
  storageClassName: local-path
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: static-web
  labels:
    app: static-web
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: static-web
  template:
    metadata:
      labels:
        app: static-web
    spec:
      initContainers:
        - name: seed
          image: busybox:1.36
          command: ["sh", "-c", "echo 'CKAD pvc web' > /content/index.html"]
          volumeMounts:
            - name: content
              mountPath: /content
      containers:
        - name: nginx
          image: nginx:1.27.3
          ports:
            - containerPort: 80
          volumeMounts:
            - name: content
              mountPath: /usr/share/nginx/html
      volumes:
        - name: content
          persistentVolumeClaim:
            claimName: web-content
EOF
  kubectl rollout status -n "$ns" deployment/static-web --timeout=150s
  # Belt and braces: (re)write the file from the nginx container itself.
  kubectl exec -n "$ns" deploy/static-web -c nginx -- \
    sh -c 'echo "CKAD pvc web" > /usr/share/nginx/html/index.html'
}

# ---------------------------------------------------------------- services

svc01() {
  local ns="$1"
  kubectl apply -n "$ns" -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  labels:
    app: web
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: nginx
          image: nginx:1.27.3
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: web
spec:
  type: ClusterIP
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
EOF
  kubectl rollout status -n "$ns" deployment/web --timeout=150s
}

svc02() {
  local ns="$1"
  kubectl apply -n "$ns" -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: api-node
spec:
  type: NodePort
  selector:
    app: api
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
EOF
  kubectl rollout status -n "$ns" deployment/api --timeout=150s
}

svc03() {
  local ns="$1"
  kubectl set selector service/shop -n "$ns" app=shop
  kubectl rollout status -n "$ns" deployment/shop --timeout=150s
}

svc04() {
  local ns="$1"
  kubectl apply -n "$ns" -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: gateway
spec:
  type: ClusterIP
  selector:
    app: gateway
  ports:
    - name: http
      port: 80
      targetPort: 80
    - name: admin
      port: 8080
      targetPort: 80
EOF
  kubectl rollout status -n "$ns" deployment/gateway --timeout=150s
}

svc05() {
  local ns="$1"
  kubectl apply -n "$ns" -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: named-web
spec:
  type: ClusterIP
  selector:
    app: named-web
  ports:
    - port: 80
      targetPort: web
EOF
  kubectl rollout status -n "$ns" deployment/named-web --timeout=150s
}

svc06() {
  local ns="$1"
  kubectl apply -n "$ns" -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: legacy-db
spec:
  type: ClusterIP
  ports:
    - port: 5432
      targetPort: 5432
---
apiVersion: v1
kind: Endpoints
metadata:
  name: legacy-db
subsets:
  - addresses:
      - ip: 192.0.2.10
    ports:
      - port: 5432
EOF
}

svc07() {
  local ns="$1"
  kubectl apply -n "$ns" -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: members
  labels:
    app: members
spec:
  replicas: 2
  selector:
    matchLabels:
      app: members
  template:
    metadata:
      labels:
        app: members
    spec:
      containers:
        - name: app
          image: busybox:1.36
          command: ["sleep", "3600"]
---
apiVersion: v1
kind: Service
metadata:
  name: members
spec:
  clusterIP: None
  selector:
    app: members
  ports:
    - port: 80
EOF
  kubectl rollout status -n "$ns" deployment/members --timeout=150s
}

svc08() {
  local ns="$1"
  kubectl patch service payments -n "$ns" --type=json \
    -p '[{"op":"replace","path":"/spec/ports/0/targetPort","value":80}]'
  kubectl rollout status -n "$ns" deployment/payments --timeout=150s
}

svc09() {
  local ns="$1"
  kubectl apply -n "$ns" -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: public-lb
spec:
  type: LoadBalancer
  selector:
    app: public
  ports:
    - port: 80
      targetPort: 80
EOF
  kubectl rollout status -n "$ns" deployment/public --timeout=150s
}

svc10() {
  local ns="$1"
  kubectl patch service edge -n "$ns" -p '{"spec":{"type":"LoadBalancer"}}'
  kubectl rollout status -n "$ns" deployment/edge --timeout=150s
}

svc11() {
  local ns="$1"
  kubectl apply -n "$ns" -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: catalog-stable
  labels:
    app: catalog
    track: stable
spec:
  replicas: 3
  selector:
    matchLabels:
      app: catalog
      track: stable
  template:
    metadata:
      labels:
        app: catalog
        track: stable
    spec:
      containers:
        - name: nginx
          image: nginx:1.26.3
          ports:
            - containerPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: catalog-canary
  labels:
    app: catalog
    track: canary
spec:
  replicas: 1
  selector:
    matchLabels:
      app: catalog
      track: canary
  template:
    metadata:
      labels:
        app: catalog
        track: canary
    spec:
      containers:
        - name: nginx
          image: nginx:1.27.3
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: catalog
spec:
  type: ClusterIP
  selector:
    app: catalog
  ports:
    - port: 80
      targetPort: 80
EOF
  kubectl rollout status -n "$ns" deployment/catalog-stable --timeout=150s
  kubectl rollout status -n "$ns" deployment/catalog-canary --timeout=150s
}

svc12() {
  local ns="$1"
  kubectl patch service catalog -n "$ns" \
    -p '{"spec":{"selector":{"app":"catalog","version":"green"}}}'
  kubectl rollout status -n "$ns" deployment/catalog-blue --timeout=150s
  kubectl rollout status -n "$ns" deployment/catalog-green --timeout=150s
}
