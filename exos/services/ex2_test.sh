#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"



test_service1=$(kubectl get svc exosvc21  -o jsonpath='{.metadata.name}' 2>/dev/null)
if [[ "$test_service1" == "exosvc21" ]]; then #Double crochet pour la comparaison de chaines, && pour "et"
  echo -e "Service exosvc21  existe: ${GREEN}OK${ENDCOLOR}"
else
  echo -e "Service existe exosvc21: ${RED}KO ${ENDCOLOR}"
  echo -e "\t ${RED} Le service exosvc21  n'existe pas ${ENDCOLOR}"
fi


portsvc=$(kubectl get svc exosvc21  -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)
targetportsvc=$(kubectl get svc exosvc21 -o jsonpath='{.spec.ports[0].targetPort}' 2>/dev/null)

if [[ "$portsvc" == "80" ]]; then 
  echo  -e "Port du  service ${GREEN} OK ${ENDCOLOR}"
else
  echo -e "Port du service ${RED} KO ${ENDCOLOR}" 
  echo  -e "\t Port trouvé: $portsvc" 
fi  
if [[ "$targetportsvc" == "8124" ]]; then 
  echo  -e "targetPort du  service ${GREEN} OK ${ENDCOLOR}"
else
  echo -e "targetPort du service ${RED} KO ${ENDCOLOR}" 
  echo  -e "\t Port trouvé: $targetportsvc" 
fi  

portnodePort=$(kubectl get svc exosvc21  -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
if [[ "$portnodePort" == "31258" ]]; then 
  echo  -e "NodePort du  service exosvc21  ${GREEN} OK ${ENDCOLOR}"
else
  echo -e "NodePort du service exosvc21 ${RED} KO ${ENDCOLOR}" 
  echo  -e "\t NodePort trouvé: $portnodePort" 
fi  

typeservice=$(kubectl get svc exosvc21  -o jsonpath='{.spec.type}' 2>/dev/null)
if [[ "$typeservice" == "NodePort" ]]; then 
  echo  -e "Type de service NodePort  pour exosvc21  ${GREEN} OK ${ENDCOLOR}"
else
  echo -e "Type de service NodePort pour exosvc21 ${RED} KO ${ENDCOLOR}" 
  echo  -e "\t Port trouvé: $typeservice" 
fi  

selectService=$(kubectl get svc exosvc21  -o jsonpath='{.spec.selector.toto}' 2>/dev/null)
if [[ "$selectService" == "dep-ex-service-2" ]]; then 
  echo  -e "Le service Expose le bon deploiement ( exosvc21)  ${GREEN} OK ${ENDCOLOR}"
else
  echo -e "Le service Expose le bon deploiement ( exosvc21) ${RED} KO ${ENDCOLOR}" 
fi  





########## service2 #########
test_service1=$(kubectl get svc exosvc22  -o jsonpath='{.metadata.name}' 2>/dev/null)
if [[ "$test_service1" == "exosvc22" ]]; then #Double crochet pour la comparaison de chaines, && pour "et"
  echo -e "Service exosvc22  existe: ${GREEN}OK${ENDCOLOR}"
else
  echo -e "Service existe exosvc22: ${RED}KO ${ENDCOLOR}"
  echo -e "\t ${RED} Le service exosvc22  n'existe pas ${ENDCOLOR}"
fi


portsvc=$(kubectl get svc exosvc22  -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)
targetportsvc=$(kubectl get svc exosvc22 -o jsonpath='{.spec.ports[0].targetPort}' 2>/dev/null)

if [[ "$portsvc" == "80" ]]; then 
  echo  -e "Port du  service ${GREEN} OK ${ENDCOLOR}"
else
  echo -e "Port du service ${RED} KO ${ENDCOLOR}" 
  echo  -e "\t Port trouvé: $portsvc" 
fi  
if [[ "$targetportsvc" == "9090" ]]; then 
  echo  -e "targetPort du  service ${GREEN} OK ${ENDCOLOR}"
else
  echo -e "targetPort du service ${RED} KO ${ENDCOLOR}" 
  echo  -e "\t Port trouvé: $targetportsvc" 
fi  


typeservice=$(kubectl get svc exosvc22  -o jsonpath='{.spec.type}' 2>/dev/null)
if [[ "$typeservice" == "LoadBalancer" ]]; then 
  echo  -e "Type de service LoadBalancer  pour exosvc22  ${GREEN} OK ${ENDCOLOR}"
else
  echo -e "Type de service LoadBalancer pour exosvc22 ${RED} KO ${ENDCOLOR}" 
  echo  -e "\t Port trouvé: $typeservice" 
fi  

selectService=$(kubectl get svc exosvc22  -o jsonpath='{.spec.selector.truc}' 2>/dev/null)
if [[ "$selectService" == "dep-ex-service-3" ]]; then 
  echo  -e "Le service Expose le bon deploiement ( exosvc22)  ${GREEN} OK ${ENDCOLOR}"
else
  echo -e "Le service Expose le bon deploiement ( exosvc22) ${RED} KO ${ENDCOLOR}" 
fi  
