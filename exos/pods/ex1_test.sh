#!/bin/bash  

RED="\e[31m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"


function get_JSON_Pods() {
    name=$1
    namespace=$2
    result=$(kubectl get  po $name -n  $namespace -o  json  2> /dev/null)
    error=$? 
    if [ $error -eq 0 ]; then
	echo  $result
	return 0 
    fi 
  echo "{}"
  return  0 
}

jsonPod=$(get_JSON_Pods ex1pod default)
#Verification du  nom du pod
namePod=$(echo "$jsonPod" | jq -r  '.metadata.name' 2>/dev/null)

if [[ -z "$namePod" ]]; then
  echo -e  "Erreur: Impossible d'extraire le nom du pod"
elif [[ "$namePod" == "ex1pod" ]]; then
  echo -e  "Le pod est bien nommé 'ex1pod'. ${GREEN} OK ${ENDCOLOR}"
else
  echo "Le pod n'est pas nommé 'ex1pod'.${RED}  KO ${ENDCOLOR}"
fi


# Vérification  namespace 
namespace=$(echo "$jsonPod" | jq -r  '.metadata.namespace' 2>/dev/null)

if [[ -z "$namespace" ]]; then
  echo -e  "Erreur: Impossible d'extraire le namespace"
elif [[ "$namespace" == "default" ]]; then
  echo -e  "Namespace  ${GREEN} OK ${ENDCOLOR}"
else
  echo -e  "Namespace ${RED}  KO ${ENDCOLOR} "
fi



# Vérification du  nombre de conteneur requis
container_count=$(echo "$jsonPod" | jq '.spec.containers | length')
if [[ $container_count -eq 1 ]]; then
  echo -e "Un seul conteneur: ${GREEN} OK ${ENDCOLOR}"
else
  echo -e "Un seul conteneur ${RED} KO ${ENDCOLOR}"
fi


# Vérification du  nom du  conteneur
containerName=$(echo "$jsonPod" | jq -r  '.spec.containers[0].name' 2>/dev/null)
if [[ "$containerName" == "premier-pod" ]]; then
  echo -e "Nom du conteneur: ${GREEN} OK ${ENDCOLOR}"
else
  echo -e "Nom du conteneur:  ${RED} KO ${ENDCOLOR} \n\t  Explication:  nom du  conteneur  trouvé: $containerName"
fi

# Vérification de l'image diu conteneur1  
containerImage=$(echo "$jsonPod" | jq -r  '.spec.containers[0].image' 2>/dev/null)
if [[ "$containerImage" == "nginx:1.27.3" ]]; then
  echo -e "Image  du conteneur: ${GREEN} OK ${ENDCOLOR}"
else
  echo -e "Image du conteneur:  ${RED} KO ${ENDCOLOR}  \n\t  Explication:  nom de  l'image  trouvé:  $containerImage"
fi
