#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"


nb_ready=$(kubectl get deployments -o jsonpath='{.status.readyReplicas}' dep1)

if [[ "$nb_ready" == "3" ]]; then 
    echo  -e "Analyse et correction déploiement dep1 ${GREEN} OK ${ENDCOLOR}"
else
    echo -e "Analyse et correction déploiement dep1 ${RED} KO ${ENDCOLOR}"
fi

# verif dep2 
container1_image=$(kubectl get deployment dep2 -o jsonpath='{.spec.template.spec.containers[?(@.name=="conteneur1")].image}' 2>/dev/null)
container1_command=$(kubectl get deployment dep2 -o jsonpath='{.spec.template.spec.containers[?(@.name=="conteneur1")].command}' 2>/dev/null)
if [[ "$container1_image" == "busybox" && "$container1_command" == "[\"sleep\",\"1000\"]" ]]; then #Double crochet pour la comparaison de chaines, && pour "et"
  echo -e "Modification de l'image et de la commande de dep2: ${GREEN}OK${ENDCOLOR}"
else
  echo -e "Modification de l'image et de la commande de dep2: ${RED}KO${ENDCOLOR}"
  echo -e "\tL'image ou la commande du conteneur1 de dep2 sont incorrectes."
  echo -e "\tImage actuelle : $container1_image, Commande actuelle: $container1_command" #Afficher les valeurs actuelles pour le debug
fi


# Verfi  dep3  
log_to_test=$(kubectl logs -l app=dep3 |sort > /tmp/exdeployResult)

if [ -e "/tmp/exDeploy2" ]; then
   logUser=$(cat /tmp/exDeploy2 |sort )
   sort /tmp/exDeploy2 > /tmp/exdeploy2_trie
   errorDiff=$(diff /tmp/exdeploy2_trie /tmp/exdeployResult)
   if [ -z "$errorDiff" ]; then
    echo -e "Sauvegarder les logs de toutes les instances de **dep3** sur le fichier /tmp/exDeploy2   ${GREEN} OK ${ENDCOLOR}"
  else
    echo -e "Sauvegarder les logs de toutes les instances de **dep3** sur le fichier /tmp/exDeploy2  ${RED} KO ${ENDCOLOR}"
    echo -e "\t Le contenu du log est incorrect : $logUser"
  fi
else 
    echo  -e "Sauvegarder les logs de toutes les instances de **dep3** sur le fichier /tmp/exDeploy2  ${RED} KO ${ENDCOLOR}"
    echo  -e "\t Fichier /tmp/exDeploy2 introuvable" 
fi

#  Verif dep4  
container1_image=$(kubectl get deployment dep4 -o jsonpath='{.spec.template.spec.containers[?(@.name=="conteneur1")].image}' 2>/dev/null)
if [[ "$container1_image" == "nginx:1.14.3" ]]; then #Double crochet pour la comparaison de chaines, && pour "et"
  echo -e "Le deploiment dep4  doit revenir sur la version 1: ${GREEN}OK${ENDCOLOR}"
else
  echo -e "Le deploiment dep4  doit revenir sur la version 1: ${RED}KO${ENDCOLOR}"
fi




