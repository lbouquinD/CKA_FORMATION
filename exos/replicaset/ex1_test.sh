#!/bin/bash  

RED="\e[31m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"


function get_JSON_Replicaset() {
    name=$1
    namespace=$2
    result=$(kubectl get  rs $name -n  $namespace -o  json  2> /dev/null)
    error=$? 
    if [ $error -eq 0 ]; then
	echo  $result
	return 0 
    fi 
  echo "{}"
  return  0 
}

jsonRs=$(get_JSON_Replicaset ex1replicaset default)
# echo  $jsonRs |jq 
#Verification du  nom du RS
nameRS=$(echo "$jsonRs" | jq -r  '.metadata.name' 2>/dev/null)

if [[ -z "$nameRS" ]]; then
  echo -e  "Erreur: Impossible d'extraire le nom du rs"
elif [[ "$nameRS" == "ex1replicaset" ]]; then
  echo -e  "Le replicaSet est bien nommé 'ex1replicaset'. ${GREEN} OK ${ENDCOLOR}"
else
  echo -e "Le replicaSet 'ex1replicaset' n'existe pas .${RED}  KO ${ENDCOLOR}"
fi


# Vérification  namespace 
namespace=$(echo "$jsonRs" | jq -r  '.metadata.namespace' 2>/dev/null)

if [[ -z "$namespace" ]]; then
  echo -e  "Erreur: Impossible d'extraire le namespace"
elif [[ "$namespace" == "default" ]]; then
  echo -e  "Namespace  ${GREEN} OK ${ENDCOLOR}"
else
  echo -e  "Namespace ${RED}  KO ${ENDCOLOR} "
fi



# Vérification du  nombre de replicas  requis
replicas_count=$(echo "$jsonRs" | jq '.spec.replicas')
if [[ $replicas_count -eq 3 ]]; then
  echo -e "Nombre de replicas: ${GREEN} OK ${ENDCOLOR}"
else
  echo -e "Nombre de replicas ${RED} KO ${ENDCOLOR}"
fi


# Vérification du  nom du  conteneur
containerName=$(echo "$jsonRs" | jq -r  '.spec.template.spec.containers[0].name' 2>/dev/null)
if [[ "$containerName" == "premier-replicaset" ]]; then
  echo -e "Nom du conteneur: ${GREEN} OK ${ENDCOLOR}"
else
  echo -e "Nom du conteneur:  ${RED} KO ${ENDCOLOR} \n\t  Explication:  nom du  conteneur  trouvé: $containerName"
fi

# Vérification de l'image diu conteneur1  
containerImage=$(echo "$jsonRs" | jq -r  '.spec.template.spec.containers[0].image' 2>/dev/null)
if [[ "$containerImage" == "nginx:1.27.3" ]]; then
  echo -e "Image  du conteneur: ${GREEN} OK ${ENDCOLOR}"
else
  echo -e "Image du conteneur:  ${RED} KO ${ENDCOLOR}  \n\t  Explication:  nom de  l'image  trouvé:  $containerImage"
fi


