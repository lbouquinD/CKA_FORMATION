#!/bin/bash


RED="\e[31m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"

echo -e "[TEST  liste des secret  dans /tmp/listSecret ]"
if [ -e "/tmp/listSecret" ]; then
   logUser=$(cat /tmp/listSecret |sort |tr -d "\n"  | sed 's/ //g' )
   if [ "$logUser" = "secret-agentsecret-contactsecret-lieusecret-operationsecret-projet" ]; then
    echo -e "\t Liste des secrets  ${GREEN} OK ${ENDCOLOR}"
  else
    echo -e "\t Liste des secrets   ${RED} KO ${ENDCOLOR}"
    echo -e "\t\t Contenu du fichier:  $(cat /tmp/listSecret)"
  fi
else 
  echo  -e "\t ${RED}  Le fichier /tmp/listSecret n'existe pas. ${ENDCOLOR}"
fi

echo -e "[TEST  contenu du secret secret-contact dans /tmp/topsecret ]"
if [ -e "/tmp/topsecret" ]; then
   logUser=$(cat /tmp/topsecret |sort |tr -d "\n" |sed 's/ //g' )
   if [ "$logUser" = "nom-du-contact-suspect:nom:contact-suspectnumero-de-telephone-du-contact-a-surveiller:numero:777-770-777" ]; then
    echo -e "\t Contenu du secret  ${GREEN} OK ${ENDCOLOR}"
  else
    echo -e "\t Contenu du secret  ${RED} KO ${ENDCOLOR}"
    echo -e "\t\t Contenu du fichier:  $(cat /tmp/topsecret)"
  fi
else 
  echo  -e "\t ${RED}  Le fichier /tmp/topsecret n'existe pas. ${ENDCOLOR}"
fi
