#!/bin/bash

# Vérifier si les variables d'environnement sont définies
if  [ -z "$NOM_POD" ]; then
  echo "La variable d'environnement   NOM_POD n'est pas définit."
  exit 1
fi
if [ -z "$NOM_APP" ] ; then
  echo "La variable d'environnement NOM_APP  n'est pas définit."
  exit 1
fi



# Boucle infinie pour que le script continue à s'exécuter
while true; do
  # Afficher les informations
  echo "Nom de l'application : $NOM_APP"
  echo "Nom du pod : $NOM_POD"
  date

  # Attendre une minute avant la prochaine itération
  sleep 60
done
