#!/bin/bash


echo  "bonjour"
# Vérifier si les variables d'environnement sont définies
if  [ -z "$NOM_POD" ]; then
  echo "La variable d'environnement   NOM_POD n'est pas définit."
  exit 1
fi
if [ -z "$NOM_APP" ] ; then
  echo "La variable d'environnement NOM_APP  n'est pas définit."
  exit 1
fi
if [ -z "$COLOR" ] ; then
   color="N/A"
fi


# Créer le fichier index.html initial
echo "<html><body><h1>Informations du conteneur</h1><p>Nom de l'application : $NOM_APP</p><p>Nom du pod : $NOM_POD</p><p>Date : $(date)</p><p>Color:  COLOR</p></body></html>" > /usr/share/nginx/html/index.html

# Démarrer Nginx en arrière-plan
nginx -g 'daemon off;' &

# Boucle infinie pour mettre à jour le fichier index.html
while true; do
  # Mettre à jour la date dans le fichier index.html
  sed -i "s/<p>Date : .*/<p>Date : $(date)/g" /usr/share/nginx/html/index.html
  echo -e "\t Nom de l'application : $NOM_APP"
  echo -e "\t Nom du pod : $NOM_POD"
  echo -e "\t COLOR: $COLOR"  
  date
  # Attendre une minute avant la prochaine mise à jour
  sleep 10
done
