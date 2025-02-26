#!/bin/bash 

RED="\e[31m\e[1m"
GREEN="\e[32m\e[1m"
ENDCOLOR="\e[0m"
BLUE="\e[34m\e[1m"



test_pvc=$(kubectl get pvc ex3pvc -ojsonpath='{.metadata.name}' 2>/dev/null)
if [[ "$test_pvc" == "ex3pvc"  ]]; then 
    echo  -e "PVC ex3pvc  exist  ? ${GREEN} OK  ${ENDCOLOR}"
else 
    echo  -e "PVC ex3pvc  exist  ? ${RED} KO  ${ENDCOLOR}"
    exit 1 
fi 

accessmode_pvc=$(kubectl get pvc ex3pvc -ojsonpath='{.spec.accessModes[0]}' 2>/dev/null)
if [[ "$accessmode_pvc" == "ReadWriteOnce"  ]]; then 
    echo  -e "accessmode ex3pvc  correct  ? ${GREEN} OK  ${ENDCOLOR}"
else 
    echo  -e "accessmode  correct  ? ${RED} KO  ${ENDCOLOR}"
    echo  -e "\t${RED} accessmode trouvé: $accessmode_pvc ${ENDCOLOR}" 

fi 

storageclass_pvc=$(kubectl get pvc ex3pvc -ojsonpath='{.spec.storageClassName}' 2>/dev/null)
if [[ "$storageclass_pvc" == "local-path"  ]]; then 
    echo  -e "storageClassName ex3pvc  correct  ? ${GREEN} OK  ${ENDCOLOR}"
else 
    echo  -e "storageClassName  correct  ? ${RED} KO  ${ENDCOLOR}"
    echo  -e "\t${RED} storageClassName trouvé: $storageclass_pvc ${ENDCOLOR}" 

fi 


askstorage_pvc=$(kubectl get pvc ex3pvc -ojsonpath='{.spec.resources.requests.storage}' 2>/dev/null)
if [[ "$askstorage_pvc" == "1Mi"  ]]; then 
    echo  -e "Quantité de stockage demandé conforme pour  ex3pvc  correct  ? ${GREEN} OK  ${ENDCOLOR}"
else 
    echo  -e "Quantité de stockage demandé conforme pour  ex3pvc  correct  ? ${RED} KO  ${ENDCOLOR}"
    echo  -e "\t${RED} Quantité demandée: $askstorage_pvc ${ENDCOLOR}" 

fi 

pod_exist=$(kubectl get  po ex3-pod-pvc -o jsonpath='{.metadata.name}' 2>/dev/null)
if [[ "$pod_exist" == "ex3-pod-pvc"  ]]; then 
    echo  -e "Pod ex3-pod-pvc  exist  ? ${GREEN} OK  ${ENDCOLOR}"
else 
    echo  -e "Pod ex3-pod-pvc  exist  ? ${RED} KO  ${ENDCOLOR}"
    exit 1 
fi 
nb_container=$(kubectl get po ex3-pod-pvc -o jsonpath='{.spec.containers[*].name}' |wc -w 2>/dev/null)
if [[ "$nb_container" == "1"  ]]; then 
    echo  -e "Nombre de conteneur ? ${GREEN} OK  ${ENDCOLOR}"
else 
    echo  -e "Nombre de conteneur? ${RED} KO  ${ENDCOLOR}"
    echo  -e "\t ${RED} nombre trouvé:  $nb_container  ${ENDCOLOR}"
    exit 1 
fi 

conteneur1_name=$(kubectl get  po ex3-pod-pvc -o jsonpath='{.spec.containers[0].name}')
if [[ "$conteneur1_name" == "conteneur1"  ]]; then 
    echo  -e "nom conteneur1 ? ${GREEN} OK  ${ENDCOLOR}"
else 
    echo  -e "nom conteneur1 ${RED} KO  ${ENDCOLOR}"
    echo  -e "\t ${RED} nom trouvé:  $conteneur1_name  ${ENDCOLOR}"
    exit 1 
fi 

conteneur1_image=$(kubectl get  po ex3-pod-pvc -o jsonpath='{.spec.containers[?(@.name == "conteneur1")].image}')
if [[ "$conteneur1_image" == "nginx:1.27.3"  ]]; then 
    echo  -e "conteneur1_image ? ${GREEN} OK  ${ENDCOLOR}"
else 
    echo  -e "conteneur1_image ${RED} KO  ${ENDCOLOR}"
    echo  -e "\t ${RED} image trouvé:  $conteneur1_image  ${ENDCOLOR}"
    exit 1 
fi 


nom_volumes=$(kubectl get  po ex3-pod-pvc  -o jsonpath='{.spec.volumes[?(@.name == "mon-volume-pvc")].name}' 2>/dev/null)
if [[ "$nom_volumes" == "mon-volume-pvc"  ]]; then 
    echo  -e "Nom du volume ? ${GREEN} OK  ${ENDCOLOR}"
else 
    echo  -e "Nom du volume ? ${RED} KO  ${ENDCOLOR}"
    echo  -e "\t ${RED} nom trouvé:  $nom_volumes  ${ENDCOLOR}"
    exit 1 
fi 


type_volume=$(kubectl get   po ex3-pod-pvc -o jsonpath='{.spec.volumes[?(@.name == "mon-volume-pvc")].persistentVolumeClaim}' 2>/dev/null)
if [[ ! -z "$type_volume"  ]]; then 
    echo  -e "Type du volume ? ${GREEN} OK  ${ENDCOLOR}"
else 
    echo  -e "Type du volume ? ${RED} KO  ${ENDCOLOR}"
    echo  -e "\t ${RED} nom trouvé:  $type_volume  ${ENDCOLOR}"
    exit 1 
fi 

claimref_volume=$(kubectl get   po ex3-pod-pvc -o jsonpath='{.spec.volumes[?(@.name == "mon-volume-pvc")].persistentVolumeClaim.claimName}' 2>/dev/null)
if [[ "$claimref_volume" == "ex3pvc"  ]]; then 
    echo  -e "Référence au pvc ex3pvc ? ${GREEN} OK  ${ENDCOLOR}"
else 
    echo  -e "Référence au pvc ex3pvc ? ${RED} KO  ${ENDCOLOR}"
    echo  -e "\t ${RED} Référence trouvée:  $claimref_volume  ${ENDCOLOR}"
    exit 1 
fi 

conteneur1_name_volume_mount=$(kubectl get  po ex3-pod-pvc  -o jsonpath='{.spec.containers[?(@.name == "conteneur1")].volumeMounts[?(@.name == "mon-volume-pvc")].name}' 2>/dev/null)
if [[ "$conteneur1_name_volume_mount" == "mon-volume-pvc"  ]]; then 
    conteneur1_mountpath_volume_mount=$(kubectl get  po ex3-pod-pvc  -o jsonpath='{.spec.containers[?(@.name == "conteneur1")].volumeMounts[?(@.name == "mon-volume-pvc")].mountPath}' 2>/dev/null)
    if [[ "$conteneur1_mountpath_volume_mount" == "/tmp/stockage"  ]]; then 
        echo  -e "montage volume sur conteneur1 ? ${GREEN} OK  ${ENDCOLOR}"
    else
        echo  -e "montage volume sur conteneur1  ${RED} KO  ${ENDCOLOR}"
    fi
else
    echo  -e "montage volume sur conteneur1  ${RED} KO  ${ENDCOLOR}"
fi


status_pvc=$(kubectl get pvc ex3pvc -ojsonpath='{.status.phase}' 2>/dev/null)
if [[ "$status_pvc" == "Bound"  ]]; then 
    echo  -e "Le pvc est operationnel  ? ${GREEN} OK  ${ENDCOLOR}"
else 
    echo  -e "Le pvc est operationnel  ? ${RED} KO  ${ENDCOLOR}"
    echo  -e "\t${RED} status du pvc: $status_pvc ${ENDCOLOR}" 

fi 