# shellcheck shell=bash
# Solutions CKAD workloads : pod-01..13, rs-01..03, deploy-01..08, ds-01..04, sts-01..05.
# Fichier destiné à être "source" par le harnais : il ne fait que définir des fonctions.
# Chaque fonction reçoit le namespace (ckad-<id>) en $1.

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# _wl_until <timeout_s> <cmd...> : relance <cmd> toutes les 2 s jusqu'à succès.
_wl_until() {
  local timeout="$1"; shift
  local end=$((SECONDS + timeout))
  until "$@" >/dev/null 2>&1; do
    (( SECONDS >= end )) && return 1
    sleep 2
  done
}

_wl_pod_exists() { kubectl get pod "$2" -n "$1" >/dev/null 2>&1; }
_wl_pod_absent() { ! kubectl get pod "$2" -n "$1" >/dev/null 2>&1; }

# Nombre de lignes "nom image ready deletionTimestamp" saines pour un label.
_wl_pods_ok() {
  # _wl_pods_ok <ns> <selector> <image> <expected_count>
  local ns="$1" sel="$2" img="$3" want="$4" out
  out="$(kubectl get pods -n "$ns" -l "$sel" \
    -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.spec.containers[0].image}{" "}{.status.conditions[?(@.type=="Ready")].status}{" "}{.metadata.deletionTimestamp}{"\n"}{end}')" || return 1
  echo "$out" | awk -v img="$img" -v want="$want" '
    NF == 0 { next }
    { total++ ; if ($2 == img && $3 == "True" && NF == 3) good++ }
    END { exit !(total == want && good == want) }'
}

# ---------------------------------------------------------------------------
# Pods
# ---------------------------------------------------------------------------

pod01() {
  local ns="$1"
  kubectl run web-dev -n "$ns" --image=nginx:alpine \
    --labels=tier=frontend --env=APP_ENV=development
  kubectl wait -n "$ns" --for=condition=Ready pod/web-dev --timeout=120s
}

pod02() {
  local ns="$1"
  kubectl annotate pod web-dev -n "$ns" builder=ansible --overwrite
  kubectl label pod web-dev -n "$ns" tier=ui stage=test --overwrite
}

pod03() {
  local ns="$1"
  kubectl get pods -n "$ns" --show-labels > /tmp/ckad-pod-03-labels.txt
  kubectl get pods -n "$ns" -l tier=ui > /tmp/ckad-pod-03-ui.txt
  kubectl run web-dev -n "$ns" --image=nginx:alpine --restart=Never \
    --labels=tier=ui,stage=test --env=APP_ENV=development \
    --dry-run=client -o yaml > /tmp/ckad-pod-03.yaml
}

pod04() {
  local ns="$1"
  kubectl run box-check -n "$ns" --image=busybox \
    --env=DB_HOST=postgres --env=DB_PORT=5432 \
    --command -- sh -c "env && sleep 3600"
  kubectl wait -n "$ns" --for=condition=Ready pod/box-check --timeout=120s
  kubectl logs -n "$ns" box-check
}

pod05() {
  local ns="$1"
  kubectl delete pod -n "$ns" -l stage=test --wait=true --timeout=90s
  kubectl delete pod box-check -n "$ns" --force --grace-period=0
}

pod06() {
  local ns="$1"
  # kubectl run nomme le conteneur comme le Pod : on renomme uniquement le
  # conteneur (à partir de la ligne "containers:").
  kubectl run web-fast -n "$ns" --image=nginx:1.27.3 --labels=app=web-fast \
    --dry-run=client -o yaml \
    | sed '/containers:/,$ s/name: web-fast/name: nginx/' \
    | kubectl apply -n "$ns" -f -
  kubectl wait -n "$ns" --for=condition=Ready pod/web-fast --timeout=120s
}

pod07() {
  local ns="$1"
  kubectl apply -n "$ns" -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: api-limited
  labels:
    app: api
    tier: backend
  annotations:
    training.ckad/owner: team-blue
spec:
  restartPolicy: Always
  containers:
    - name: api
      image: nginx:1.27.3
      resources:
        requests:
          cpu: 50m
          memory: 32Mi
        limits:
          cpu: 100m
          memory: 64Mi
EOF
  kubectl wait -n "$ns" --for=condition=Ready pod/api-limited --timeout=120s
}

pod08() {
  local ns="$1"
  kubectl apply -n "$ns" -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: sidecar-logger
spec:
  volumes:
    - name: shared-logs
      emptyDir: {}
  containers:
    - name: writer
      image: busybox:1.36
      command: ["sh", "-c", "while true; do date >> /var/log/shared/app.log; sleep 5; done"]
      volumeMounts:
        - name: shared-logs
          mountPath: /var/log/shared
    - name: reader
      image: busybox:1.36
      command: ["sh", "-c", "tail -F /var/log/shared/app.log"]
      volumeMounts:
        - name: shared-logs
          mountPath: /var/log/shared
EOF
  kubectl wait -n "$ns" --for=condition=Ready pod/sidecar-logger --timeout=120s
}

pod09() {
  local ns="$1"
  kubectl apply -n "$ns" -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: initialized-web
spec:
  volumes:
    - name: web-content
      emptyDir: {}
  initContainers:
    - name: prepare
      image: busybox:1.36
      command: ["sh", "-c", "echo 'CKAD initialized' > /work/index.html"]
      volumeMounts:
        - name: web-content
          mountPath: /work
  containers:
    - name: web
      image: nginx:1.27.3
      ports:
        - containerPort: 80
      volumeMounts:
        - name: web-content
          mountPath: /usr/share/nginx/html
EOF
  kubectl wait -n "$ns" --for=condition=Ready pod/initialized-web --timeout=120s
}

pod10() {
  local ns="$1"
  # Les sondes d'un Pod sont immuables : suppression puis recréation.
  kubectl delete pod probe-web -n "$ns" --wait=true --timeout=60s
  kubectl apply -n "$ns" -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: probe-web
spec:
  containers:
    - name: web
      image: nginx:1.27.3
      ports:
        - containerPort: 80
      readinessProbe:
        httpGet:
          path: /
          port: 80
        initialDelaySeconds: 2
      livenessProbe:
        httpGet:
          path: /
          port: 80
        initialDelaySeconds: 2
EOF
  kubectl wait -n "$ns" --for=condition=Ready pod/probe-web --timeout=120s
}

pod11() {
  local ns="$1"
  kubectl describe pod looping-worker -n "$ns" >/dev/null 2>&1
  kubectl delete pod looping-worker -n "$ns" --wait=true --timeout=60s
  kubectl apply -n "$ns" -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: looping-worker
spec:
  restartPolicy: Always
  containers:
    - name: worker
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
EOF
  kubectl wait -n "$ns" --for=condition=Ready pod/looping-worker --timeout=120s
}

pod12() {
  local ns="$1"
  kubectl delete pod configured-app -n "$ns" --wait=true --timeout=60s
  kubectl apply -n "$ns" -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: configured-app
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "while true; do sleep 3600; done"]
      env:
        - name: APP_MODE
          value: production
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
EOF
  kubectl wait -n "$ns" --for=condition=Ready pod/configured-app --timeout=120s
}

pod13() {
  local ns="$1"
  # L'inventaire attend les deux Pods en phase Running.
  kubectl wait -n "$ns" --for=condition=Ready pod/ops-reporter pod/obsolete-pod --timeout=120s
  kubectl logs -n "$ns" ops-reporter -c reporter > /tmp/ckad-pod-13
  kubectl get pods -n "$ns" --sort-by=.metadata.name \
    -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.spec.containers[0].image}{" "}{.status.phase}{"\n"}{end}' \
    > /tmp/ckad-pod-13.txt
  kubectl delete pod obsolete-pod -n "$ns" --wait=true --timeout=60s
}

# ---------------------------------------------------------------------------
# ReplicaSets
# ---------------------------------------------------------------------------

rs01() {
  local ns="$1"
  kubectl apply -n "$ns" -f - <<'EOF'
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: frontend-rs
spec:
  replicas: 3
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
        - name: nginx
          image: nginx:1.27.3
EOF
  kubectl wait -n "$ns" rs/frontend-rs --for=jsonpath='{.status.availableReplicas}'=3 --timeout=150s
}

rs02() {
  local ns="$1"
  # spec.selector d'un ReplicaSet apps/v1 est immuable : on recrée.
  kubectl delete rs api-rs -n "$ns" --wait=true --timeout=90s
  kubectl apply -n "$ns" -f - <<'EOF'
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: api-rs
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api-v2
  template:
    metadata:
      labels:
        app: api-v2
    spec:
      containers:
        - name: api
          image: nginx:1.27.3
EOF
  kubectl wait -n "$ns" rs/api-rs --for=jsonpath='{.status.availableReplicas}'=3 --timeout=150s
}

rs03() {
  local ns="$1" victim
  kubectl scale rs worker-rs -n "$ns" --replicas=5
  kubectl wait -n "$ns" rs/worker-rs --for=jsonpath='{.status.availableReplicas}'=5 --timeout=120s
  # Supprimer un Pod présent dès le départ (référence : ConfigMap rs03-baseline).
  victim="$(kubectl get configmap rs03-baseline -n "$ns" -o jsonpath='{.data.pods}' | awk 'NF{print $1; exit}')"
  if [[ -z "$victim" ]]; then
    victim="$(kubectl get pods -n "$ns" -l app=worker -o jsonpath='{.items[0].metadata.name}')"
  fi
  kubectl delete pod "$victim" -n "$ns" --wait=true --timeout=60s
  _wl_until 120 _wl_pods_ok "$ns" app=worker nginx:1.27.3 5
  kubectl wait -n "$ns" rs/worker-rs --for=jsonpath='{.status.availableReplicas}'=5 --timeout=60s
  kubectl get pods -n "$ns" -l app=worker \
    -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | LC_ALL=C sort > /tmp/ckad-rs-03.txt
}

# ---------------------------------------------------------------------------
# Deployments
# ---------------------------------------------------------------------------

deploy01() {
  local ns="$1"
  # Le conteneur prend le nom de l'image : "nginx".
  kubectl create deployment web -n "$ns" --image=nginx:1.27.3 --replicas=3 --port=80
  kubectl rollout status deployment/web -n "$ns" --timeout=150s
}

deploy02() {
  local ns="$1"
  kubectl scale deployment catalog -n "$ns" --replicas=5
  kubectl rollout status deployment/catalog -n "$ns" --timeout=150s
  kubectl get deployment catalog -n "$ns" --no-headers \
    | awk '{print $1, $2, $3, $4}' > /tmp/ckad-deploy-02.txt
}

deploy03() {
  local ns="$1"
  kubectl annotate deployment storefront -n "$ns" \
    kubernetes.io/change-cause="upgrade to nginx 1.27.3" --overwrite
  kubectl set image deployment/storefront -n "$ns" nginx=nginx:1.27.3
  kubectl rollout status deployment/storefront -n "$ns" --timeout=170s
}

deploy04() {
  local ns="$1" rev
  kubectl rollout history deployment/payments -n "$ns"
  # Révision la plus récente portant "stable release" (attendu : 2).
  rev="$(kubectl get rs -n "$ns" -l app=payments \
    -o jsonpath='{range .items[*]}{.metadata.annotations.deployment\.kubernetes\.io/revision}{"|"}{.metadata.annotations.kubernetes\.io/change-cause}{"\n"}{end}' \
    | awk -F'|' '$2 == "stable release" {print $1}' | sort -n | tail -1)"
  [[ -n "$rev" ]] || rev=2
  kubectl rollout undo deployment/payments -n "$ns" --to-revision="$rev"
  kubectl rollout status deployment/payments -n "$ns" --timeout=150s
}

deploy05() {
  local ns="$1"
  kubectl apply -n "$ns" -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: critical-api
spec:
  replicas: 4
  revisionHistoryLimit: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
  selector:
    matchLabels:
      app: critical-api
  template:
    metadata:
      labels:
        app: critical-api
    spec:
      containers:
        - name: api
          image: nginx:1.27.3
EOF
  kubectl rollout status deployment/critical-api -n "$ns" --timeout=150s
}

deploy06() {
  local ns="$1"
  # replace : réécrit tout le spec (supprime la commande parasite).
  kubectl replace -n "$ns" -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: broken-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: broken-api
  template:
    metadata:
      labels:
        app: broken-api
    spec:
      containers:
        - name: api
          image: nginx:1.27.3
          ports:
            - containerPort: 80
          readinessProbe:
            httpGet:
              path: /
              port: 80
          resources:
            limits:
              cpu: 200m
              memory: 128Mi
EOF
  kubectl rollout status deployment/broken-api -n "$ns" --timeout=170s
}

deploy07() {
  local ns="$1"
  # spec.selector d'un Deployment apps/v1 est immuable : on recrée.
  kubectl delete deployment orders -n "$ns" --wait=true --timeout=90s
  kubectl apply -n "$ns" -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: orders
spec:
  replicas: 2
  selector:
    matchLabels:
      app: orders
  template:
    metadata:
      labels:
        app: orders
    spec:
      containers:
        - name: orders
          image: nginx:1.27.3
EOF
  kubectl rollout status deployment/orders -n "$ns" --timeout=150s
}

deploy08() {
  local ns="$1"
  kubectl apply -n "$ns" -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-stable
spec:
  replicas: 4
  selector:
    matchLabels:
      app: frontend
      track: stable
  template:
    metadata:
      labels:
        app: frontend
        track: stable
    spec:
      containers:
        - name: nginx
          image: nginx:1.26.3
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-canary
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
      track: canary
  template:
    metadata:
      labels:
        app: frontend
        track: canary
    spec:
      containers:
        - name: nginx
          image: nginx:1.27.3
EOF
  kubectl rollout status deployment/frontend-stable -n "$ns" --timeout=150s
  kubectl rollout status deployment/frontend-canary -n "$ns" --timeout=60s
  kubectl get deployments -n "$ns" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' \
    | LC_ALL=C sort > /tmp/ckad-deploy-08.txt
}

# ---------------------------------------------------------------------------
# DaemonSets
# ---------------------------------------------------------------------------

ds01() {
  local ns="$1"
  kubectl apply -n "$ns" -f - <<'EOF'
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-agent
  labels:
    app: node-agent
spec:
  selector:
    matchLabels:
      app: node-agent
  template:
    metadata:
      labels:
        app: node-agent
    spec:
      containers:
        - name: agent
          image: busybox:1.36
          command: ["sh", "-c", "sleep 3600"]
EOF
  kubectl rollout status daemonset/node-agent -n "$ns" --timeout=150s
}

ds02() {
  local ns="$1"
  kubectl apply -n "$ns" -f - <<'EOF'
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: linux-collector
spec:
  selector:
    matchLabels:
      app: linux-collector
  template:
    metadata:
      labels:
        app: linux-collector
    spec:
      nodeSelector:
        kubernetes.io/os: linux
      containers:
        - name: collector
          image: busybox:1.36
          command: ["sh", "-c", "sleep 3600"]
EOF
  kubectl rollout status daemonset/linux-collector -n "$ns" --timeout=150s
}

ds03() {
  local ns="$1"
  kubectl patch daemonset log-agent -n "$ns" --type=json -p '[
    {"op": "add", "path": "/spec/template/spec/tolerations", "value": [
      {"key": "dedicated", "operator": "Equal", "value": "observability", "effect": "NoSchedule"}
    ]}
  ]'
  kubectl rollout status daemonset/log-agent -n "$ns" --timeout=150s
}

ds04() {
  local ns="$1"
  # 1) stratégie OnDelete d'abord, pour que le changement d'image ne déclenche rien.
  kubectl patch daemonset manual-agent -n "$ns" --type=merge \
    -p '{"spec":{"updateStrategy":{"type":"OnDelete","rollingUpdate":null}}}'
  # 2) nouvelle image dans le template.
  kubectl set image daemonset/manual-agent -n "$ns" agent=busybox:1.36
  # 3) suppression des anciens Pods -> recréés avec le nouveau template.
  kubectl delete pod -n "$ns" -l app=manual-agent --wait=true --timeout=90s
  local desired
  _wl_until 60 kubectl get daemonset manual-agent -n "$ns"
  desired="$(kubectl get daemonset manual-agent -n "$ns" -o jsonpath='{.status.desiredNumberScheduled}')"
  [[ -n "$desired" && "$desired" != 0 ]] || desired=1
  _wl_until 120 _wl_pods_ok "$ns" app=manual-agent busybox:1.36 "$desired"
  kubectl get pods -n "$ns" -l app=manual-agent \
    -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | LC_ALL=C sort > /tmp/ckad-ds-04.txt
}

# ---------------------------------------------------------------------------
# StatefulSets
# ---------------------------------------------------------------------------

sts01() {
  local ns="$1"
  kubectl apply -n "$ns" -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: web-headless
spec:
  clusterIP: None
  selector:
    app: stateful-web
  ports:
    - port: 80
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: stateful-web
spec:
  serviceName: web-headless
  replicas: 3
  selector:
    matchLabels:
      app: stateful-web
  template:
    metadata:
      labels:
        app: stateful-web
    spec:
      containers:
        - name: nginx
          image: nginx:1.27.3
          ports:
            - containerPort: 80
EOF
  kubectl rollout status statefulset/stateful-web -n "$ns" --timeout=170s
}

sts02() {
  local ns="$1"
  kubectl apply -n "$ns" -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: db-headless
spec:
  clusterIP: None
  selector:
    app: db
  ports:
    - port: 80
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: db
spec:
  serviceName: db-headless
  replicas: 3
  podManagementPolicy: OrderedReady
  selector:
    matchLabels:
      app: db
  template:
    metadata:
      labels:
        app: db
    spec:
      volumes:
        - name: data
          emptyDir: {}
      initContainers:
        - name: identity
          image: busybox:1.36
          command: ["sh", "-c", "hostname > /data/identity"]
          volumeMounts:
            - name: data
              mountPath: /data
      containers:
        - name: database
          image: busybox:1.36
          command: ["sleep", "3600"]
          volumeMounts:
            - name: data
              mountPath: /data
EOF
  kubectl rollout status statefulset/db -n "$ns" --timeout=170s
}

sts03() {
  local ns="$1"
  kubectl apply -n "$ns" -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: cache-headless
spec:
  clusterIP: None
  selector:
    app: cache
  ports:
    - port: 80
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: cache
spec:
  serviceName: cache-headless
  replicas: 2
  selector:
    matchLabels:
      app: cache
  template:
    metadata:
      labels:
        app: cache
    spec:
      containers:
        - name: cache
          image: busybox:1.36
          command: ["sleep", "3600"]
          volumeMounts:
            - name: data
              mountPath: /data
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: local-path
        resources:
          requests:
            storage: 100Mi
EOF
  kubectl rollout status statefulset/cache -n "$ns" --timeout=150s
  kubectl exec -n "$ns" cache-0 -c cache -- sh -c 'echo persisted > /data/marker'
  # sleep (PID 1) ignore SIGTERM : on raccourcit la période de grâce.
  kubectl delete pod cache-0 -n "$ns" --grace-period=1 --wait=true --timeout=60s
  _wl_until 60 _wl_pod_exists "$ns" cache-0
  kubectl wait -n "$ns" --for=condition=Ready pod/cache-0 --timeout=90s
  kubectl exec -n "$ns" cache-0 -c cache -- cat /data/marker
  kubectl rollout status statefulset/cache -n "$ns" --timeout=60s
}

sts04() {
  local ns="$1"
  # Un seul patch : la partition est en place avant que l'image ne change.
  kubectl patch statefulset rolling-db -n "$ns" --type=merge -p '{
    "spec": {
      "replicas": 4,
      "updateStrategy": {"type": "RollingUpdate", "rollingUpdate": {"partition": 2}},
      "template": {"spec": {"containers": [{"name": "db", "image": "nginx:1.27.3"}]}}
    }
  }'
  _wl_until 170 _sts04_done "$ns"
}

_sts04_done() {
  local ns="$1" out
  out="$(kubectl get pods -n "$ns" -l app=rolling-db \
    -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.spec.containers[0].image}{" "}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}')" || return 1
  echo "$out" | awk '
    $1 == "rolling-db-0" && $2 == "nginx:1.26.3" && $3 == "True" { ok++ }
    $1 == "rolling-db-1" && $2 == "nginx:1.26.3" && $3 == "True" { ok++ }
    $1 == "rolling-db-2" && $2 == "nginx:1.27.3" && $3 == "True" { ok++ }
    $1 == "rolling-db-3" && $2 == "nginx:1.27.3" && $3 == "True" { ok++ }
    END { exit !(ok == 4) }' || return 1
  [[ "$(kubectl get statefulset rolling-db -n "$ns" -o jsonpath='{.status.readyReplicas}')" == 4 ]]
}

sts05() {
  local ns="$1"
  # serviceName et selector sont immuables : suppression (en cascade, pour
  # libérer les noms sessions-0/1) puis recréation.
  kubectl delete statefulset sessions -n "$ns" --cascade=foreground --wait=true --timeout=90s
  _wl_until 60 _wl_pod_absent "$ns" sessions-0
  _wl_until 60 _wl_pod_absent "$ns" sessions-1
  kubectl apply -n "$ns" -f - <<'EOF'
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: sessions
spec:
  serviceName: sessions-headless
  replicas: 2
  selector:
    matchLabels:
      app: sessions
  template:
    metadata:
      labels:
        app: sessions
    spec:
      containers:
        - name: sessions
          image: nginx:1.27.3
EOF
  kubectl rollout status statefulset/sessions -n "$ns" --timeout=120s
  kubectl get pods -n "$ns" -l app=sessions \
    -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | LC_ALL=C sort > /tmp/ckad-sts-05.txt
  kubectl delete statefulset sessions -n "$ns" --cascade=orphan --wait=true --timeout=60s
}
