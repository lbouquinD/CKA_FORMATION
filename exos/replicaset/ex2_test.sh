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

jsonRs=$(get_JSON_Replicaset testresplicatset default)


if [ -e "/tmp/ex2NbReplicaset" ]; then
   logUser=$(cat /tmp/ex2NbReplicaset | tr -d '\n' | sed 's/ //g')
   if [ "$logUser" = "3" ]; then
    echo -e "Nombre de replicaset ${GREEN} OK ${ENDCOLOR}"
  else
    echo -e "Test nombre de replicaset  ${RED} KO ${ENDCOLOR}"
    echo -e "\t Le contenu de /tmp/ex2NbReplicaset est incorrect $logUser"
  fi
else
  echo -e "Test nombre de replicaset  ${RED} KO ${ENDCOLOR}"
  echo -e "\t ${RED}Le fichier /tmp/ex2NbReplicaset n'existe pas. ${ENDCOLOR}"
fi

# Vérification du  nombre de replicas  requis
replicas_count=$(echo "$jsonRs" | jq '.spec.replicas')
if [[ $replicas_count -eq 5 ]]; then
  echo -e "Nombre de replicas: ${GREEN} OK ${ENDCOLOR}"
else
  echo -e "Nombre de replicas ${RED} KO ${ENDCOLOR}"
fi


