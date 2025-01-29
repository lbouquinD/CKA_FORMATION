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

jsonPod=$(get_JSON_Pods ex2pod default)
#Verification du  nom du pod
namePod=$(echo "$jsonPod" | jq -r  '.metadata.name' 2>/dev/null)

if [[ -z "$namePod" ]]; then
  echo -e  "Erreur: Impossible d'extraire le nom du pod"
elif [[ "$namePod" == "ex2pod" ]]; then
  echo -e  "Le pod est bien nommé 'ex2pod'. ${GREEN} OK ${ENDCOLOR}"
else
  echo -e "Le pod n'est pas nommé 'ex2pod'.${RED}  KO ${ENDCOLOR}"
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
if [[ $container_count -eq 2 ]]; then
  echo -e "Nombre de conteneur : ${GREEN} OK ${ENDCOLOR}"
else
  echo -e "Nombre de conteneur ${RED} KO ${ENDCOLOR} \n\t  Explication nombre de conteneurs  trouvé: $container_count"
fi


# Vérification du  nom du  conteneur1
containerName1=$(echo "$jsonPod" | jq -r  '.spec.containers[0].name' 2>/dev/null)
if [[ "$containerName1" == "conteneur1" ]]; then
  echo -e "Nom du conteneur1: ${GREEN} OK ${ENDCOLOR}"
else
  echo -e "Nom du conteneur1:  ${RED} KO ${ENDCOLOR} \n\t  Explication:  nom du  conteneur  trouvé: $containerName1"
fi

# Vérification de l'image du conteneur1  
containerImage=$(echo "$jsonPod" | jq -r  '.spec.containers[0].image' 2>/dev/null)
if [[ "$containerImage" == "nginx:1.27.3" ]]; then
  echo -e "Image  du conteneur1: ${GREEN} OK ${ENDCOLOR}"
else
  echo -e "Image du conteneur1:  ${RED} KO ${ENDCOLOR}  \n\t  Explication:  nom de  l'image  trouvé:  $containerImage"
fi


# Vérification du  nom du  conteneur2
containerName2=$(echo "$jsonPod" | jq -r  '.spec.containers[1].name' 2>/dev/null)
if [[ "$containerName2" == "conteneur2" ]]; then
  echo -e "Nom du conteneur2: ${GREEN} OK ${ENDCOLOR}"
else
  echo -e "Nom du conteneur2:  ${RED} KO ${ENDCOLOR} \n\t  Explication:  nom du  conteneur  trouvé: $containerName2"
fi

# Vérification de l'image du conteneur1  
containerImage2=$(echo "$jsonPod" | jq -r  '.spec.containers[1].image' 2>/dev/null)
if [[ "$containerImage2" == "busybox" ]]; then
  echo -e "Image  du conteneur2: ${GREEN} OK ${ENDCOLOR}"
else
  echo -e "Image du conteneur2:  ${RED} KO ${ENDCOLOR}  \n\t  Explication:  nom de  l'image  trouvé:  $containerImage2"
fi


# Vérification de la commande du conteneur2 
containerCommand2=$(echo "$jsonPod" | jq -r  '.spec.containers[1].command' | tr -d '\n' | sed 's/ //g' 2>/dev/null)
if [[ "$containerCommand2" == "[\"sleep\",\"1000\"]" ]]; then
  echo -e "Commande du conteneur2: ${GREEN} OK ${ENDCOLOR}"
else
  echo -e "Commande du conteneur2:  ${RED} KO ${ENDCOLOR}  \n\t  Explication:  nom de  la commande  trouvé:  $containerCommand2"
fi



# echo  "$jsonPod" | jq