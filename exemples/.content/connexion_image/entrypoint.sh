#!/bin/sh

if  [ -z "$NOMAPP" ]; then
  echo -e "\033[31m La variable d'environnement   URL n'est pas défini.\033[0m"
  exit 1
fi
if  [ -z "$URL" ]; then
  echo -e "\033[31m La variable d'environnement   URL n'est pas défini.\033[0m"
  exit 1
fi
if [ -z "$APPDESTPORT" ] ; then
   echo -e "\033[38;5;214m WARNING \033[0m : La variable d'environnement APPPORT  n'est pas défini. Port par défault => 80 \033[0m"
   APPDESTPORT=80
fi


# Définir le port d'écoute par défaut si non défini
LISTENPORT=${LISTENPORT:-80}
# Modifier le fichier de configuration de Nginx pour écouter sur le port spécifié
echo -e "[ $(date) ] Démarrage de Nginx sur le port $LISTENPORT"
sed -i "s/listen       80;/listen       $LISTENPORT;/g" /etc/nginx/conf.d/default.conf


# Démarrer Nginx en arrière-plan
nginx -g 'daemon off;' &
while true; do
  echo -e "[ $(date) ] Je suis l'app $NOMAPP : tentative de connexion sur $URL:$APPDESTPORT"
  
  # Effectuer la requête avec un timeout de 5 secondes
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 $URL:$APPDESTPORT)
  
  # Vérifier le code de retour
  if [ "$HTTP_CODE" -eq 200 ]; then
    echo -e "\033[32m \t Connexion OK (Code: $HTTP_CODE)\033[0m"
  else
    echo -e "\033[31m \t Connexion KO (Code: $HTTP_CODE)\033[0m"
  fi
  
  # Attendre 5 secondes avant la prochaine tentative
  sleep 5
done