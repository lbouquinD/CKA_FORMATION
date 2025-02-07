#!/bin/sh

if  [ -z "$NOMAPP" ]; then
  echo -e "\033[31m La variable d'environnement   NOMAPP n'est pas défini.\033[0m"
  exit 1
fi
if [ -z "$NOMAPPDEST" ] ; then
  echo -e "\033[31m La variable d'environnement NOM_APP  n'est pas défini.\033[0m"
  exit 1
fi
if [ -z "$NAMESPACEDEST" ] ; then
   echo -e "\033[31m La variable d'environnement NAMESPACEDEST  n'est pas défini.\033[0m"
   exit 1
fi

if [ -z "$APPDESTPORT" ] ; then
   echo -e "\033[38;5;214m WARNING \033[0m : La variable d'environnement APPPORT  n'est pas défini. Port par défault => 80 \033[0m"
   APPDESTPORT=80
fi

while true; do
  echo -e "[ $(date) ] Je suis l'app $NOMAPP : tentative de connexion sur $NOMAPPDEST.$NAMESPACEDEST.svc.cluster.local:$APPDESTPORT"
  
  # Effectuer la requête avec un timeout de 5 secondes
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 $NOMAPPDEST.$NAMESPACEDEST.svc.cluster.local:$APPDESTPORT)
  
  # Vérifier le code de retour
  if [ "$HTTP_CODE" -eq 200 ]; then
    echo -e "\033[32m \t Connexion OK (Code: $HTTP_CODE)\033[0m"
  else
    echo -e "\033[31m \t Connexion KO (Code: $HTTP_CODE)\033[0m"
  fi
  
  # Attendre 5 secondes avant la prochaine tentative
  sleep 5
done