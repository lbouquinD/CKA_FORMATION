#!/bin/bash 

# Dossier de départ (peut être modifié)
dossier_depart="."

# Trouver tous les fichiers .sh dans les sous-dossiers
find "$dossier_depart" -type f -name "*.sh" -print0 | while IFS= read -r -d $'\0' fichier; do
  # Changer le mode d'exécution (ajouter le droit d'exécution pour le propriétaire)
  chmod u+x "$fichier"
  echo "Mode d'exécution modifié pour : $fichier"
done

echo "Terminé !"
