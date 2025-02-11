#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"


test_po=$(kubectl get  po test  -o jsonpath='{.metadata.name}' 2>/dev/null)

if [[ "$test_po" == "test" ]]; then 
    echo  -e "Création pod avec le nom test  ${GREEN} OK ${ENDCOLOR}"
else
    echo -e "Création pod avec le nom test ${RED} KO ${ENDCOLOR}"
    echo -e "\t ${RED} Le pod n'existe pas ${ENDCOLOR}"
fi

# verif dep2 
container1_image=$(kubectl get po test -o jsonpath='{.spec.containers[?(@.name=="test")].image}' 2>/dev/null)
if [[ "$container1_image" == "nginx:1.27.3" ]]; then #Double crochet pour la comparaison de chaines, && pour "et"
  echo -e "Image du pod test: ${GREEN}OK${ENDCOLOR}"
else
  echo -e "Image du pod test: ${RED}KO ${ENDCOLOR}"
  echo -e "\t ${RED} L'image est  incorrect:  image du pods test actuel: $container1_image ${ENDCOLOR}"
fi


test_service=$(kubectl get svc test-svc-ex1  -o jsonpath='{.metadata.name}' 2>/dev/null)
if [[ "$test_service" == "test-svc-ex1" ]]; then #Double crochet pour la comparaison de chaines, && pour "et"
  echo -e "Service test-svc-ex1  existe: ${GREEN}OK${ENDCOLOR}"
else
  echo -e "Service existe test-svc-ex1: ${RED}KO ${ENDCOLOR}"
  echo -e "\t ${RED} Le service test-svc-ex1  n'existe pas ${ENDCOLOR}"
fi


portsvc=$(kubectl get svc test-svc-ex1  -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)
targetportsvc=$(kubectl get svc test-svc-ex1  -o jsonpath='{.spec.ports[0].targetPort}' 2>/dev/null)

if [[ "$portsvc" == "80" ]]; then 
  echo  -e "Port du  service ${GREEN} OK ${ENDCOLOR}"
else
  echo -e "Port du service ${RED} KO ${ENDCOLOR}" 
  echo  -e "\t Port trouvé: $portsvc" 
fi  
if [[ "$targetportsvc" == "80" ]]; then 
  echo  -e "targetPort du  service ${GREEN} OK ${ENDCOLOR}"
else
  echo -e "targetPort du service ${RED} KO ${ENDCOLOR}" 
  echo  -e "\t Port trouvé: $targetportsvc" 
fi  

typeservice=$(kubectl get svc test-svc-ex1  -o jsonpath='{.spec.type}' 2>/dev/null)
if [[ "$typeservice" == "ClusterIP" ]]; then 
  echo  -e "Type de service ClusterIP  ${GREEN} OK ${ENDCOLOR}"
else
  echo -e "Type de service ClusterIP ${RED} KO ${ENDCOLOR}" 
  echo  -e "\t Port trouvé: $typeservice" 
fi  
