#!/bin/bash 

RED="\e[31m\e[1m"
GREEN="\e[32m\e[1m"
ENDCOLOR="\e[0m"
BLUE="\e[34m\e[1m"


pod_exist=$(kubectl get  po ex2-hostpath -o jsonpath='{.metadata.name}' 2>/dev/null)
if [[ "$pod_exist" == "ex2-hostpath"  ]]; then 
    echo  -e "Pod ex2-hostpath  exist  ? ${GREEN} OK  ${ENDCOLOR}"
else 
    echo  -e "Pod ex2-hostpath  exist  ? ${RED} KO  ${ENDCOLOR}"
    exit 1 
fi 
nb_container=$(kubectl get po ex2-hostpath -o jsonpath='{.spec.containers[*].name}' |wc -w 2>/dev/null)
if [[ "$nb_container" == "1"  ]]; then 
    echo  -e "Nombre de conteneur ? ${GREEN} OK  ${ENDCOLOR}"
else 
    echo  -e "Nombre de conteneur? ${RED} KO  ${ENDCOLOR}"
    echo  -e "\t ${RED} nombre trouvé:  $nb_container  ${ENDCOLOR}"
    exit 1 
fi 

conteneur1_name=$(kubectl get  po ex2-hostpath -o jsonpath='{.spec.containers[0].name}')
if [[ "$conteneur1_name" == "conteneur1"  ]]; then 
    echo  -e "nom conteneur1 ? ${GREEN} OK  ${ENDCOLOR}"
else 
    echo  -e "nom conteneur1 ${RED} KO  ${ENDCOLOR}"
    echo  -e "\t ${RED} nom trouvé:  $conteneur1_name  ${ENDCOLOR}"
    exit 1 
fi 

conteneur1_image=$(kubectl get  po ex2-hostpath -o jsonpath='{.spec.containers[?(@.name == "conteneur1")].image}')
if [[ "$conteneur1_image" == "nginx:1.27.3"  ]]; then 
    echo  -e "conteneur1_image ? ${GREEN} OK  ${ENDCOLOR}"
else 
    echo  -e "conteneur1_image ${RED} KO  ${ENDCOLOR}"
    echo  -e "\t ${RED} image trouvé:  $conteneur1_image  ${ENDCOLOR}"
    exit 1 
fi 


nom_volumes=$(kubectl get  po ex2-hostpath  -o jsonpath='{.spec.volumes[?(@.name == "mon-volume-hostpath")].name}' 2>/dev/null)
if [[ "$nom_volumes" == "mon-volume-hostpath"  ]]; then 
    echo  -e "Nom du volume ? ${GREEN} OK  ${ENDCOLOR}"
else 
    echo  -e "Nom du volume ? ${RED} KO  ${ENDCOLOR}"
    echo  -e "\t ${RED} nom trouvé:  $nom_volumes  ${ENDCOLOR}"
    exit 1 
fi 


type_volume=$(kubectl get   po ex2-hostpath  -o jsonpath='{.spec.volumes[?(@.name == "mon-volume-hostpath")].hostPath}' 2>/dev/null)
if [[ ! -z "$type_volume"  ]]; then 
    echo  -e "Type du volume ? ${GREEN} OK  ${ENDCOLOR}"
else 
    echo  -e "Type du volume ? ${RED} KO  ${ENDCOLOR}"
    echo  -e "\t ${RED} nom trouvé:  $type_volume  ${ENDCOLOR}"
    exit 1 
fi 

path_volume=$(kubectl get   po ex2-hostpath  -o jsonpath='{.spec.volumes[?(@.name == "mon-volume-hostpath")].hostPath.path}' 2>/dev/null)
if [[ "$path_volume" == "/tmp/ex2hostpath"  ]]; then 
    echo  -e "Path hôte du volume ? ${GREEN} OK  ${ENDCOLOR}"
else 
    echo  -e "Path hôte du volume ? ${RED} KO  ${ENDCOLOR}"
    echo  -e "\t ${RED} path trouvé:  $path_volume  ${ENDCOLOR}"
    exit 1 
fi 

path_type_volume=$(kubectl get   po ex2-hostpath  -o jsonpath='{.spec.volumes[?(@.name == "mon-volume-hostpath")].hostPath.type}' 2>/dev/null)
if [[ "$path_type_volume" == "DirectoryOrCreate"  ]]; then 
    echo  -e "hostpathtype du volume ? ${GREEN} OK  ${ENDCOLOR}"
else 
    echo  -e "hostpathtype du volume ? ${RED} KO  ${ENDCOLOR}"
    echo  -e "\t ${RED} path trouvé:  $path_type_volume  ${ENDCOLOR}"
    exit 1 
fi 



conteneur1_name_volume_mount=$(kubectl get  po ex2-hostpath  -o jsonpath='{.spec.containers[?(@.name == "conteneur1")].volumeMounts[?(@.name == "mon-volume-hostpath")].name}' 2>/dev/null)
if [[ "$conteneur1_name_volume_mount" == "mon-volume-hostpath"  ]]; then 
    conteneur1_mountpath_volume_mount=$(kubectl get  po ex2-hostpath  -o jsonpath='{.spec.containers[?(@.name == "conteneur1")].volumeMounts[?(@.name == "mon-volume-hostpath")].mountPath}' 2>/dev/null)
    if [[ "$conteneur1_mountpath_volume_mount" == "/tmp"  ]]; then 
        echo  -e "montage volume sur conteneur1 ? ${GREEN} OK  ${ENDCOLOR}"
    else
        echo  -e "montage volume sur conteneur1  ${RED} KO  ${ENDCOLOR}"
    fi
else
    echo  -e "montage volume sur conteneur1  ${RED} KO  ${ENDCOLOR}"
fi
