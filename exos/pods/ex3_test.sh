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

jsonPod=$(get_JSON_Pods podinitcontainer default)
#Verification du  nom du pod
namePod=$(echo "$jsonPod" | jq -r  '.metadata.name' 2>/dev/null)

if [[ -z "$namePod" ]]; then
  echo -e  "Erreur: Impossible d'extraire le nom du pod"
elif [[ "$namePod" == "podinitcontainer" ]]; then
  echo -e  "Le pod est bien nommé 'podinitcontainer'. ${GREEN} OK ${ENDCOLOR}"
else
  echo -e "Le pod n'est pas nommé 'podinitcontainer'.${RED}  KO ${ENDCOLOR}"
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
container_count=$(echo "$jsonPod" | jq '.spec.initContainers | length')
if [[ $container_count -eq 1 ]]; then
  echo -e "nombre initConteneur : ${GREEN} OK ${ENDCOLOR}"
else
  echo -e "nombre initConteneur ${RED} KO ${ENDCOLOR} \n\t  Explication nombre initConteneur trouvé: $container_count"
fi


# Vérification du  nombre de init conteneur requis
initcontainer_count=$(echo "$jsonPod" | jq '.spec.containers | length')
if [[ $initcontainer_count -eq 1 ]]; then
  echo -e "Nombre de conteneur : ${GREEN} OK ${ENDCOLOR}"
else
  echo -e "Nombre de conteneur ${RED} KO ${ENDCOLOR} \n\t  Explication nombre de conteneurs  trouvé: $initcontainer_count"
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


# Vérification du  nom de l'init conteneur
initconteneurName=$(echo "$jsonPod" | jq -r  '.spec.initContainers[0].name' 2>/dev/null)
if [[ "$initconteneurName" == "initconteneur" ]]; then
  echo -e "Nom init Conteneur1: ${GREEN} OK ${ENDCOLOR}"
else
  echo -e "Nom init Conteneur1:  ${RED} KO ${ENDCOLOR} \n\t  Explication:  Nom init Conteneur1  trouvé: $initconteneurName"
fi

# Vérification de Image init Conteneur1
initcontainerImage=$(echo "$jsonPod" | jq -r  '.spec.initContainers[0].image' 2>/dev/null)
if [[ "$initcontainerImage" == "busybox" ]]; then
  echo -e "Image init Conteneur1: ${GREEN} OK ${ENDCOLOR}"
else
  echo -e "Image init Conteneur1:  ${RED} KO ${ENDCOLOR}  \n\t  Explication:  Image init Conteneur1 trouvé:  $initcontainerImage"
fi


# Vérification de la commande du conteneur2 
initcontainerCommand=$(echo "$jsonPod" | jq -r  '.spec.initContainers[0].command' | tr -d '\n' | sed 's/ //g' 2>/dev/null)
if [[ "$initcontainerCommand" == "[\"sleep\",\"10\"]" ]]; then
  echo -e "Commande  de l'init  conteneur: ${GREEN} OK ${ENDCOLOR}"
else
  echo -e "Commande  de l'init  conteneur:  ${RED} KO ${ENDCOLOR}  \n\t  Explication:  Commande  de l'init  conteneur  trouvé:  $initcontainerCommand"
fi



# echo  "$jsonPod" | jq