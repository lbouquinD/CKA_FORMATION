#!/bin/bash  

RED="\e[31m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"


# Vérification des logs
log_to_test="BonjourdepuislePod1" 

if [ -e "/tmp/logPod1" ]; then
   logUser=$(cat /tmp/logPod1 | tr -d '\n' | sed 's/ //g')
   if [ "$logUser" = "$log_to_test" ]; then
    echo -e "Test  logs  ${GREEN} OK ${ENDCOLOR}"
  else
    echo -e "Test  logs  ${RED} KO ${ENDCOLOR}"
    echo -e "\t Le contenu des logs est incorrect : $logUser"
  fi

   
else
  echo  -e "${RED} Le fichier /tmp/logPod1 n'existe pas. ${ENDCOLOR}"
  echo  -e "\t Test  de la récupération des Logs ${RED} KO ${ENDcOLOR}"
fi



if [ -e "/tmp/nbConteneurPod1" ]; then
   logUser=$(cat /tmp/nbConteneurPod1 | tr -d '\n' | sed 's/ //g')
   if [ "$logUser" = "1" ]; then
    echo -e "Nombre conteneur(s)  ${GREEN} OK ${ENDCOLOR}"
  else
    echo -e "Test nombre de Conteneur(s)  ${RED} KO ${ENDCOLOR}"
    echo -e "\t Le contenu de /tmp/nbConteneurPod1 est incorrect $logUser"
  fi

   
else
  echo  -e "Test  de la récupération du nombre de Pod ${RED} KO ${ENDCOLOR} "
  echo  -e "\t ${RED}Le fichier /tmp/nbConteneurPod1 n'existe pas. ${ENDCOLOR}"
fi

exist_pod=$(kubectl  get po  pod1 2>/dev/null |grep pod1 |wc -l   )
if [ "$exist_pod" -eq 1 ]; then
  # Si la variable est égale à 1, exécuter ce bloc
  echo -e "Test  existence pod ${RED} KO ${ENDCOLOR}"
  echo -e "\t le pod existe"
else
  # Sinon, exécuter ce bloc
  echo  -e "Test  existence pod ${GREEN} OK ${ENDCOLOR}"
fi




