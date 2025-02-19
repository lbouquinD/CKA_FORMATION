#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"

# Fonction pour tester la connectivité depuis un pod
test_connectivity() {
  local source_namespace=$1
  local source_pod=$2
  local dest_namespace=$3
  local dest_service=$4
  local expected_result=$5 # "success" ou "failure"

    #Récupérer le type de service
  service_type=$(kubectl get service "$dest_service" -n "$dest_namespace" -o jsonpath='{.spec.type}')

  # Déterminer l'IP de destination en fonction du type de service
  if [[ "$service_type" == "ExternalName" ]]; then
    dest_ip="$dest_service.$dest_namespace.svc.cluster.local"
  else
    dest_ip=$(kubectl get service "$dest_service" -n "$dest_namespace" -o jsonpath='{.spec.clusterIP}')
  fi

  # Executer curl depuis le pod source
  result=$(kubectl exec -it $source_pod -n $source_namespace -- curl --connect-timeout 5 -s $dest_ip:80 2>/dev/null )

  if [[ "$expected_result" == "success" ]]; then
    if [[ ! -z "$result" ]]; then # Vérifier si curl a retourné quelque chose (succès)
      echo -e "Test connectivité $source_namespace/$source_pod -> $dest_namespace/$dest_service : ${GREEN}OK${ENDCOLOR}"
      return 0
    else
      echo -e "Test connectivité $source_namespace/$source_pod -> $dest_namespace/$dest_service : ${RED}KO${ENDCOLOR}"
      return 1
    fi
  else # expected_result == "failure"
    if [[ -z "$result" ]]; then # Vérifier si curl n'a rien retourné (échec)
      echo -e "Test de non connectivité $source_namespace/$source_pod -> $dest_namespace/$dest_service : ${GREEN}OK${ENDCOLOR}"
      return 0
    else
      echo -e "Test de non connectivité $source_namespace/$source_pod -> $dest_namespace/$dest_service : ${RED}KO${ENDCOLOR} (Le service ne devrait pas pouvoir se connecter )"
      return 1
    fi
  fi
}


check_endpoint_subset() {
  local service_name=$1
  local namespace=$2

  # Vérifier si .subsets existe (retourne vide si non)
  subsets=$(kubectl get endpoints "$service_name" -n "$namespace" -o jsonpath='{.subsets}' 2>/dev/null)

  # Si $subsets est vide, il n'y a pas de subsets, on retourne 0
  if [[ -z "$subsets" ]]; then
    echo 0
  else
    echo 1 # Sinon, il y a au moins un subset, on retourne 1
  fi
}

# Créer un pod de test dans le namespace dev (busybox)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: test
---

apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  namespace: test
  labels:
    app: test
spec:
  containers:
  - name: test-container
    image: nginx
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: test
spec:
  selector:
    app: test
    app: monitoring
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
EOF

# Créer un pod de test dans le namespace monitoring (busybox)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: test-pod-monitoring
  namespace: monitoring
  labels:
    app: monitoring
spec:
  containers:
  - name: test-container
    image: nginx

EOF

# Créer un pod de test dans le namespace prod (busybox)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name:  test-pod-prod
  namespace: prod
  labels:
    app: prod
spec:
  containers:
  - name: test-container
    image: nginx
EOF


# Créer un pod de test dans le namespace prod (busybox)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name:  test-pod-dev
  namespace: dev
  labels:
    test: dev
spec:
  containers:
  - name: test-container
    image: nginx
---
apiVersion: v1
kind: Service
metadata:
  name: test-svc-dev
  namespace: dev
spec:
  selector:
    test: dev
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
EOF
# Attendre que les pods soient prêts
kubectl wait --for=condition=Ready pod/test-pod -n test --timeout=60s
kubectl wait --for=condition=Ready pod/test-pod-monitoring -n monitoring --timeout=60s
kubectl wait --for=condition=Ready pod/test-pod-prod -n prod --timeout=60s
kubectl wait --for=condition=Ready pod/test-pod-dev -n dev --timeout=60s

echo  -e "[Test des services] \n"
if [[ $(check_endpoint_subset "nginx-service" "prod") -eq 0 ]]; then
  echo -e " ${RED}Erreur: Le service nginx-service dans prod n'a pas de endpoint Vérifier que ex1.yaml  ait bien eété appliqué. Le script s'arrête.${ENDCOLOR}"
  exit 1  # Code de sortie 1 pour indiquer une erreur
fi

if [[ $(check_endpoint_subset "nginx-service" "monitoring") -eq 0 ]]; then
  echo -e " ${RED}Erreur: Le service nginx-service dans monitoring n'a pas de endpoint Vérifier que ex1.yaml  ait bien eété appliqué. Le script s'arrête.${ENDCOLOR}"
  exit 1  # Code de sortie 1 pour indiquer une erreur
fi
echo  -e "${GREEN} OK ${ENDCOLOR}\n"
# Tests

# 1. blockall (prod) : Aucun trafic entrant/sortant
echo  -e "[TEST  BlockAll  prod]\n"
test_connectivity prod test-pod-prod dev nginx-service failure
test_connectivity prod test-pod-prod monitoring nginx-service failure
test_connectivity prod test-pod-prod prod google failure
test_connectivity test test-pod prod nginx-service failure
test_connectivity monitoring test-pod-monitoring prod nginx-service failure
test_connectivity dev test-pod-dev dev google  success

# 2. allow-mon-app (dev) : Trafic entrant vers nginx-dev
echo  -e "[TEST  allow-mon-app  prod]\n"
test_connectivity test test-pod dev nginx-service success
test_connectivity test test-pod dev test-svc-dev failure 



# # 3. allow-monitoring (dev) : Communication depuis dev vers monitoring
# test_connectivity dev test-pod-dev monitoring test-pod-monitoring success
# test_connectivity monitoring test-pod-monitoring monitoring test-pod-monitoring success # Test depuis monitoring vers monitoring (devrait aussi marcher)

# # Nettoyage (facultatif)
# # kubectl delete pod test-pod-dev -n dev
# # kubectl delete pod test-pod-monitoring -n monitoring

# echo "" # Saut de ligne final