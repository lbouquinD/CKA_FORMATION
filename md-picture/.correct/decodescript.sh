#!/bin/bash

# Fichier d'entrée contenant le code base64
input_file=$1

# Extraire le contenu entre bash <(echo ' et )
start_pattern="bash <(echo '"
end_pattern=")"

start_pos=$(grep -o -b "$start_pattern" "$input_file" | cut -d: -f1)
end_pos=$(grep -o -b "$end_pattern" "$input_file" | cut -d: -f1)

if [[ -n "$start_pos" && -n "$end_pos" && "$end_pos" > "$start_pos" ]]; then
  start_pos=$((start_pos + ${#start_pattern} )) # Ajuster la position de départ
  content=$(dd if="$input_file" bs=1 skip="$start_pos" count=$((end_pos - start_pos)))

  # Décoder le contenu base64
  decoded_content=$(echo "$content" | base64 -d)

  # Enregistrer le contenu décodé dans un fichier
  output_file=$1  # Nom de fichier plus clair
  echo "$decoded_content" > "$output_file"

  echo "Script décodé et enregistré dans : $output_file"

  # Optionnel : Rendre le script exécutable
  chmod +x "$output_file"

else
  echo "Motif de début ou de fin non trouvé, ou ordre incorrect."
fi