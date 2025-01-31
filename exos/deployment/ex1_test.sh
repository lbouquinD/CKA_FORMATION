#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"



# verif exdeployment 
container1_image=$(kubectl get deployment exdeployment -o jsonpath='{.spec.template.spec.containers[?(@.name=="conteneur1")].image}' 2>/dev/null)
container1_name=$(kubectl get deployment exdeployment -o jsonpath='{.spec.template.spec.containers[?(@.name=="conteneur1")].name}' 2>/dev/null)
if [[ "$container1_image" == "nginx:1.27.3" && "$container1_name" == "conteneur1" ]]; then #Double crochet pour la comparaison de chaines, && pour "et"
  echo -e "Création deploiement 1 nom Deploiement et  Image: ${GREEN}OK${ENDCOLOR}"
else
  echo -e "Création deploiement 1 nom Deploiement et  Image: ${RED}KO${ENDCOLOR}"
  echo -e "\tle nom du conteneur ou  l'image est  incorrecte"
  echo -e "\tImage actuelle : $container1_image,nom_conteneur: $container1_name" #Afficher les valeurs actuelles pour le debug
fi


# verif labels 

labels=$( kubectl get deployment exdeployment -o jsonpath='{.spec.selector.matchLabels}')
if  [[ "$labels" == "{\"app\":\"frontend\",\"formation\":\"ckad\"}" ]];then 
    echo -e "Ajout des labels ${GREEN}OK${ENDCOLOR}"
else 
     echo -e "Ajout des labels  ${RED}KO${ENDCOLOR}"
     echo  -e "\t Labels trouvé: $labels"
fi
 