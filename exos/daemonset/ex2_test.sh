#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"



#Verif  ex  
log_to_test=$(kubectl get  daemonset -o=custom-columns='Name:.metadata.name' |grep -v Name |sort > /tmp/exdeployResult)

if [ -e "/tmp/exdaemon1" ]; then
   logUser=$(cat /tmp/exdaemon1 |sort )
   sort /tmp/exdaemon1 > /tmp/exdaemon1_trie
   errorDiff=$(diff /tmp/exdaemon1_trie /tmp/exdeployResult)
   if [ -z "$errorDiff" ]; then
    echo -e "Lister des daemonset  présent  sur le cluster dans le fichier **/tmp/exdaemon1**  dans le namespace default   ${GREEN} OK ${ENDCOLOR}"
  else
    echo -e "Lister des daemonset  présent  sur le cluster dans le fichier **/tmp/exdaemon1**  dans le namespace default  ${RED} KO ${ENDCOLOR}"
    echo -e "\t Le contenu du log est incorrect : $logUser"
  fi
else 
    echo  -e "Lister des daemonset  présent  sur le cluster dans le fichier **/tmp/exdaemon1**  dans le namespace default  ${RED} KO ${ENDCOLOR}"
    echo  -e "\t Fichier /tmp/exdaemon1 introuvable" 
fi