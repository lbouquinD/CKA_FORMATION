#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"



# verif daemonset 
container1_image=$(kubectl get daemonset exdaemon -o jsonpath='{.spec.template.spec.containers[?(@.name=="conteneur1")].image}' 2>/dev/null)
container1_name=$(kubectl get daemonset exdaemon -o jsonpath='{.spec.template.spec.containers[?(@.name=="conteneur1")].name}' 2>/dev/null)
if [[ "$container1_image" == "nginx:1.27.3" && "$container1_name" == "conteneur1" ]]; then #Double crochet pour la comparaison de chaines, && pour "et"
  echo -e "Création daemonset 1 nom daemonset et  Image: ${GREEN}OK${ENDCOLOR}"
else
  echo -e "Création daemonset 1 nom daemonset et  Image: ${RED}KO${ENDCOLOR}"
  echo -e "\tle nom du conteneur ou  l'image est  incorrecte"
  echo -e "\tImage actuelle : $container1_image, .nom_conteneur: $container1_name" #Afficher les valeurs actuelles pour le debug
fi