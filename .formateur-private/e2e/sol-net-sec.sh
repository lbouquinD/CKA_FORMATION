# Solutions CKAD : networkpolicies, ingress, secrets, probes, resources.
# Fichier a sourcer : il ne definit que des fonctions. $1 = namespace (ckad-<id>).

# --- helpers -----------------------------------------------------------------

_sol_wait_pod_ready() { # ns pod
  kubectl wait -n "$1" --for=condition=Ready "pod/$2" --timeout=120s
}

_sol_wait_pod_count() { # ns selector count : attend que les anciens Pods aient disparu
  local i n
  for i in $(seq 1 30); do
    n="$(kubectl get pods -n "$1" -l "$2" --no-headers 2>/dev/null | wc -l | tr -d ' ')"
    [[ "$n" == "$3" ]] && return 0
    sleep 2
  done
  return 0
}

# --- NetworkPolicies -----------------------------------------------------------

np01() {
  kubectl apply -n "$1" -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-ingress
spec:
  podSelector: {}
  policyTypes:
    - Ingress
EOF
}

np02() {
  kubectl apply -n "$1" -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-allow
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: web
      ports:
        - protocol: TCP
          port: 80
EOF
}

np03() {
  # Le namespace ckad-np-03-clients porte deja role=clients (setup) ; on le reaffirme.
  kubectl label namespace ckad-np-03-clients role=clients --overwrite
  kubectl apply -n "$1" -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-clients
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              role: clients
      ports:
        - protocol: TCP
          port: 80
EOF
}

np04() {
  kubectl apply -n "$1" -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-egress
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
    - Egress
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: db
      ports:
        - protocol: TCP
          port: 5432
EOF
}

np05() {
  kubectl patch networkpolicy allow-web -n "$1" --type=merge \
    -p '{"spec":{"podSelector":{"matchLabels":{"app":"web"}}}}'
}

np06() {
  kubectl apply -n "$1" -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: locked-api
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: web
      ports:
        - protocol: TCP
          port: 80
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: db
      ports:
        - protocol: TCP
          port: 5432
EOF
}

# --- Ingress -----------------------------------------------------------------

ing01() {
  kubectl apply -n "$1" -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web
spec:
  ingressClassName: ckad
  rules:
    - host: web.ckad.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web
                port:
                  number: 80
EOF
}

ing02() {
  kubectl apply -n "$1" -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: shop
spec:
  ingressClassName: ckad
  rules:
    - host: shop.ckad.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: shop
                port:
                  number: 80
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: api
                port:
                  number: 80
EOF
}

ing03() {
  kubectl patch ingress app -n "$1" --type=json -p '[
    {"op":"replace","path":"/spec/rules/0/http/paths/0/backend/service/name","value":"web"},
    {"op":"replace","path":"/spec/rules/0/http/paths/0/backend/service/port/number","value":80}
  ]'
}

ing04() {
  kubectl apply -n "$1" -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: colors
spec:
  ingressClassName: ckad
  rules:
    - host: blue.ckad.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: blue
                port:
                  number: 80
    - host: green.ckad.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: green
                port:
                  number: 80
EOF
}

ing05() {
  kubectl apply -n "$1" -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: secure
spec:
  ingressClassName: ckad
  tls:
    - hosts:
        - secure.ckad.local
      secretName: web-tls
  rules:
    - host: secure.ckad.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web
                port:
                  number: 80
EOF
}

ing06() {
  # "add" remplace aussi la valeur si une classe par defaut a ete injectee.
  kubectl patch ingress web -n "$1" --type=json -p '[
    {"op":"add","path":"/spec/ingressClassName","value":"ckad"},
    {"op":"replace","path":"/spec/rules/0/http/paths/0/path","value":"/"},
    {"op":"replace","path":"/spec/rules/0/http/paths/0/pathType","value":"Prefix"}
  ]'
}

# --- Secrets -----------------------------------------------------------------

sec01() {
  kubectl create secret generic db-creds -n "$1" \
    --from-literal=username=dbadmin \
    --from-literal=password='Ck4d-db-91' \
    --dry-run=client -o yaml | kubectl apply -n "$1" -f -
}

sec02() {
  kubectl create secret generic file-creds -n "$1" \
    --from-file=username=/tmp/ckad-sec-02/username \
    --from-file=password=/tmp/ckad-sec-02/password \
    --dry-run=client -o yaml | kubectl apply -n "$1" -f -
}

sec03() {
  kubectl apply -n "$1" -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: client
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sleep", "3600"]
      env:
        - name: API_USER
          valueFrom:
            secretKeyRef:
              name: api-token
              key: user
        - name: API_TOKEN
          valueFrom:
            secretKeyRef:
              name: api-token
              key: token
EOF
  _sol_wait_pod_ready "$1" client
}

sec04() {
  # defaultMode 256 = 0400 octal (ecrit en decimal pour eviter toute ambiguite YAML).
  kubectl apply -n "$1" -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: config-reader
spec:
  containers:
    - name: box
      image: busybox:1.36
      command: ["sleep", "3600"]
      volumeMounts:
        - name: settings
          mountPath: /etc/settings
          readOnly: true
  volumes:
    - name: settings
      secret:
        secretName: app-config
        defaultMode: 256
        items:
          - key: config.properties
            path: config.properties
          - key: token
            path: token
EOF
  _sol_wait_pod_ready "$1" config-reader
}

sec05() {
  kubectl create secret tls shop-tls -n "$1" \
    --cert=/tmp/ckad-sec-05/tls.crt \
    --key=/tmp/ckad-sec-05/tls.key \
    --dry-run=client -o yaml | kubectl apply -n "$1" -f -
}

sec06() {
  kubectl patch deployment gateway -n "$1" --type=strategic -p '{
    "spec":{"template":{"spec":{
      "volumes":[{"name":"certs","secret":{"secretName":"web-tls"}}],
      "containers":[{"name":"nginx","volumeMounts":[{"name":"certs","mountPath":"/etc/nginx/certs","readOnly":true}]}]
    }}}}'
  kubectl rollout status deployment/gateway -n "$1" --timeout=150s
  _sol_wait_pod_count "$1" app=gateway 2
}

# --- Probes --------------------------------------------------------------------

probe01() {
  kubectl apply -n "$1" -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: web
spec:
  containers:
    - name: nginx
      image: nginx:1.27.3
      ports:
        - containerPort: 80
      readinessProbe:
        httpGet:
          path: /
          port: 80
        initialDelaySeconds: 2
        periodSeconds: 5
      livenessProbe:
        httpGet:
          path: /
          port: 80
        initialDelaySeconds: 5
        periodSeconds: 10
EOF
  _sol_wait_pod_ready "$1" web
}

probe02() {
  kubectl apply -n "$1" -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: worker
spec:
  containers:
    - name: box
      image: busybox:1.36
      command: ["sh", "-c", "touch /tmp/healthy && sleep 3600"]
      readinessProbe:
        exec:
          command: ["cat", "/tmp/healthy"]
        initialDelaySeconds: 5
        periodSeconds: 10
      livenessProbe:
        exec:
          command: ["cat", "/tmp/healthy"]
        initialDelaySeconds: 5
        periodSeconds: 10
EOF
  _sol_wait_pod_ready "$1" worker
}

probe03() {
  kubectl apply -n "$1" -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: web
spec:
  containers:
    - name: nginx
      image: nginx:1.27.3
      ports:
        - containerPort: 80
      livenessProbe:
        tcpSocket:
          port: 80
        periodSeconds: 5
      readinessProbe:
        tcpSocket:
          port: 80
        periodSeconds: 5
EOF
  _sol_wait_pod_ready "$1" web
}

probe04() {
  kubectl apply -n "$1" -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: web
spec:
  containers:
    - name: nginx
      image: nginx:1.27.3
      ports:
        - containerPort: 80
      startupProbe:
        httpGet:
          path: /
          port: 80
        periodSeconds: 5
        failureThreshold: 12
      livenessProbe:
        httpGet:
          path: /
          port: 80
        periodSeconds: 10
      readinessProbe:
        httpGet:
          path: /
          port: 80
        periodSeconds: 5
EOF
  _sol_wait_pod_ready "$1" web
}

probe05() {
  # JSON patch : remplace les sondes entieres (la liveness passe de tcpSocket a httpGet).
  kubectl patch deployment shop -n "$1" --type=json -p '[
    {"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe",
     "value":{"httpGet":{"path":"/","port":80},"initialDelaySeconds":3,"periodSeconds":5}},
    {"op":"replace","path":"/spec/template/spec/containers/0/livenessProbe",
     "value":{"httpGet":{"path":"/","port":80},"initialDelaySeconds":5,"periodSeconds":10}},
    {"op":"add","path":"/spec/template/spec/containers/0/startupProbe",
     "value":{"httpGet":{"path":"/","port":80},"periodSeconds":5,"failureThreshold":6}}
  ]'
  kubectl rollout status deployment/shop -n "$1" --timeout=170s
}

# --- Resources -----------------------------------------------------------------

res01() {
  kubectl apply -n "$1" -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: api
spec:
  containers:
    - name: api
      image: nginx:1.27.3
      resources:
        requests:
          cpu: 100m
          memory: 64Mi
        limits:
          cpu: 200m
          memory: 128Mi
EOF
  _sol_wait_pod_ready "$1" api
}

res02() {
  kubectl apply -n "$1" -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: billing
spec:
  replicas: 2
  selector:
    matchLabels:
      app: billing
  template:
    metadata:
      labels:
        app: billing
    spec:
      containers:
        - name: app
          image: nginx:1.27.3
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 50m
              memory: 64Mi
EOF
  kubectl rollout status deployment/billing -n "$1" --timeout=150s
}

res03() {
  kubectl apply -n "$1" -f - <<'EOF'
apiVersion: v1
kind: LimitRange
metadata:
  name: defaults
spec:
  limits:
    - type: Container
      max:
        cpu: 500m
        memory: 256Mi
      min:
        cpu: 20m
        memory: 32Mi
      default:
        cpu: 200m
        memory: 128Mi
      defaultRequest:
        cpu: 50m
        memory: 64Mi
EOF
  sleep 2
  local attempt cpu
  for attempt in 1 2 3; do
    kubectl apply -n "$1" -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: plain
spec:
  containers:
    - name: web
      image: nginx:1.27.3
EOF
    cpu="$(kubectl get pod plain -n "$1" -o jsonpath='{.spec.containers[0].resources.requests.cpu}')"
    [[ -n "$cpu" ]] && break
    # LimitRange pas encore vu a l'admission : on recree le Pod.
    kubectl delete pod plain -n "$1" --wait=true
    sleep 3
  done
  _sol_wait_pod_ready "$1" plain
}

res04() {
  kubectl apply -n "$1" -f - <<'EOF'
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-quota
spec:
  hard:
    pods: "4"
    requests.cpu: 500m
    requests.memory: 256Mi
    limits.cpu: "1"
    limits.memory: 512Mi
EOF
  # Attendre que le controleur ait calcule le statut de la quota (sinon "status unknown for quota").
  local i
  for i in $(seq 1 30); do
    [[ -n "$(kubectl get resourcequota team-quota -n "$1" -o jsonpath='{.status.hard.pods}')" ]] && break
    sleep 1
  done
  kubectl apply -n "$1" -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
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
          resources:
            requests:
              cpu: 100m
              memory: 64Mi
            limits:
              cpu: 200m
              memory: 128Mi
EOF
  kubectl rollout status deployment/web -n "$1" --timeout=150s
}

res05() {
  kubectl patch deployment api -n "$1" --type=strategic -p '{
    "spec":{"replicas":2,"template":{"spec":{"containers":[{"name":"api",
      "resources":{"requests":{"cpu":"50m","memory":"32Mi"},"limits":{"cpu":"100m","memory":"64Mi"}}}]}}}}'
  kubectl rollout status deployment/api -n "$1" --timeout=170s
}
