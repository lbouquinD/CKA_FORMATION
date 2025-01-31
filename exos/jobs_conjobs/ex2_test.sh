#!/bin/bash


RED="\e[31m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"



# verif job 
container1_image=$(kubectl get cronjob mon-cronjob -o jsonpath='{.spec.jobTemplate.spec.template.spec.containers[?(@.name=="task-exec")].image}' 2>/dev/null)
container1_name=$(kubectl get cronjob mon-cronjob -o jsonpath='{.spec.jobTemplate.spec.template.spec.containers[?(@.name=="task-exec")].name}' 2>/dev/null)
if [[ "$container1_image" == "alpine" && "$container1_name" == "task-exec" ]]; then 
  echo -e "Création cronjob 1 nom conteneur et Image: ${GREEN}OK${ENDCOLOR}"
else
  echo -e "Création cronjob 1 nom conteneur et  Image: ${RED}KO${ENDCOLOR}"
  echo -e "\tle nom du conteneur ou  l'image est  incorrecte"
  echo -e "\tImage actuelle : $container1_image, nom_conteneur: $container1_name" 
fi

command=$(kubectl get cronjob mon-cronjob -o jsonpath='{.spec.jobTemplate.spec.template.spec.containers[?(@.name=="task-exec")].command}' 2>/dev/null)


#  Verif commandc
if [[ "$command" == "[\"/bin/sh\",\"-c\",\"echo \\\"Tâche exécutée à \$(date)\\\"\"]" ]]; then 
  echo -e "Création cronjob mon-cronjob command: ${GREEN}OK${ENDCOLOR}"
else
  echo -e "CCréation cronjob mon-cronjob command: ${RED}KO${ENDCOLOR}"
fi

# verif restart  policy 

restartPolicy=$(kubectl get job ex1job -o jsonpath='{.spec.template.spec.restartPolicy}')
if [[ "$restartPolicy" == "Never" ]]; then 
    echo  -e "Création  Job 1  restartPolicy ${GREEN} OK ${ENDCOLOR}"
else 
    echo  -e "Création  Job 1  restartPolicy ${GREEN} KO ${ENDCOLOR}"
    echo  -e " Politique de redémarrage trouvé: $restartpolicy" 
fi