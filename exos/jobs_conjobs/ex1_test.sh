#!/bin/bash


RED="\e[31m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"



# verif job 
container1_image=$(kubectl get job ex1job -o jsonpath='{.spec.template.spec.containers[?(@.name=="premier-job")].image}' 2>/dev/null)
container1_name=$(kubectl get job ex1job -o jsonpath='{.spec.template.spec.containers[?(@.name=="premier-job")].name}' 2>/dev/null)
if [[ "$container1_image" == "busybox" && "$container1_name" == "premier-job" ]]; then #Double crochet pour la comparaison de chaines, && pour "et"
  echo -e "Création job 1 nom conteneur et Image: ${GREEN}OK${ENDCOLOR}"
else
  echo -e "Création job 1 nom conteneur et  Image: ${RED}KO${ENDCOLOR}"
  echo -e "\tle nom du conteneur ou  l'image est  incorrecte"
  echo -e "\tImage actuelle : $container1_image, nom_conteneur: $container1_name" #Afficher les valeurs actuelles pour le debug
fi



#  Verif commandc
command=$( kubectl logs jobs/ex1job premier-job  | tr -d '\n' | sed 's/ //g')
totest=$(echo 'bonjour depuis mon premier job' | sed 's/ //g')
if [[ "$totest" == "$command" ]]; then #Double crochet pour la comparaison de chaines, && pour "et"
  echo -e "Création job 1 command: ${GREEN}OK${ENDCOLOR}"
else
  echo -e "COmmand incorrect: ${RED}KO${ENDCOLOR}"
fi


#  verif restart  policy 

restartPolicy=$(kubectl get job ex1job -o jsonpath='{.spec.template.spec.restartPolicy}')
if [[ "$restartPolicy" == "Never" ]]; then 
    echo  -e "Création  Job 1  restartPolicy ${GREEN} OK ${ENDCOLOR}"
else 
    echo  -e "Création  Job 1  restartPolicy ${GREEN} KO ${ENDCOLOR}"
    echo  -e " Politique de redémarrage trouvé: $restartpolicy" 
fi