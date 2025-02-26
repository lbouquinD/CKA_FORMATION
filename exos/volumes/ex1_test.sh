#!/bin/bash 

RED="\e[31m\e[1m"
GREEN="\e[32m\e[1m"
ENDCOLOR="\e[0m"
BLUE="\e[34m\e[1m"


dep_exist=$(kubectl get  deployment dep-emptydir -o jsonpath='{.metadata.name}' 2>/dev/null)
if [[ "$dep_exist" == "dep-emptydir"  ]]; then 
    echo  -e "Déploiement dep-emptydir  exist  ? ${GREEN} OK  ${ENDCOLOR}"
else 
    echo  -e "Déploiement dep-emptydir  exist  ? ${RED} KO  ${ENDCOLOR}"
    exit 1 
fi 
nb_container=$(kubectl get  deployment dep-emptydir -o jsonpath='{.spec.template.spec.containers[*].name}' |wc -w 2>/dev/null)
if [[ "$nb_container" == "2"  ]]; then 
    echo  -e "Nombre de conteneur ? ${GREEN} OK  ${ENDCOLOR}"
else 
    echo  -e "Nombre de conteneur? ${RED} KO  ${ENDCOLOR}"
    echo  -e "\t ${RED} nombre trouvé:  $nb_container  ${ENDCOLOR}"
    exit 1 
fi 

conteneur1_name=$(kubectl get  deployment dep-emptydir -o jsonpath='{.spec.template.spec.containers[0].name}')
if [[ "$conteneur1_name" == "conteneur1"  ]]; then 
    echo  -e "nom conteneur1 ? ${GREEN} OK  ${ENDCOLOR}"
else 
    echo  -e "nom conteneur1 ${RED} KO  ${ENDCOLOR}"
    echo  -e "\t ${RED} nom trouvé:  $conteneur1_name  ${ENDCOLOR}"
    exit 1 
fi 


conteneur2_name=$(kubectl get  deployment dep-emptydir -o jsonpath='{.spec.template.spec.containers[1].name}')
if [[ "$conteneur2_name" == "conteneur2"  ]]; then 
    echo  -e "nom conteneur2 ? ${GREEN} OK  ${ENDCOLOR}"
else 
    echo  -e "nom conteneur2 ${RED} KO  ${ENDCOLOR}"
    echo  -e "\t ${RED} nom trouvé:  $conteneur2_name  ${ENDCOLOR}"
    exit 1 
fi 


conteneur1_image=$(kubectl get  deployment dep-emptydir -o jsonpath='{.spec.template.spec.containers[?(@.name == "conteneur1")].image}')
if [[ "$conteneur1_image" == "nginx:1.27.3"  ]]; then 
    echo  -e "conteneur1_image ? ${GREEN} OK  ${ENDCOLOR}"
else 
    echo  -e "conteneur1_image ${RED} KO  ${ENDCOLOR}"
    echo  -e "\t ${RED} image trouvé:  $conteneur1_image  ${ENDCOLOR}"
    exit 1 
fi 

conteneur2_image=$(kubectl get  deployment dep-emptydir -o jsonpath='{.spec.template.spec.containers[?(@.name == "conteneur2")].image}')
if [[ "$conteneur2_image" == "wardsco/sleep"  ]]; then 
    echo  -e "conteneur2_image ? ${GREEN} OK  ${ENDCOLOR}"
else 
    echo  -e "conteneur2_image ${RED} KO  ${ENDCOLOR}"
    echo  -e "\t ${RED} image trouvé:  $conteneur2_image  ${ENDCOLOR}"
    exit 1 
fi 


nb_volumes=$(kubectl get  deployment dep-emptydir -o jsonpath='{.spec.template.spec.volumes[*].name}' |wc -w 2>/dev/null)
if [[ "$nb_volumes" == "1"  ]]; then 
    echo  -e "Nombre de volumes ? ${GREEN} OK  ${ENDCOLOR}"
else 
    echo  -e "Nombre de volumes? ${RED} KO  ${ENDCOLOR}"
    echo  -e "\t ${RED} nombre trouvé:  $nb_volumes  ${ENDCOLOR}"
    exit 1 
fi 


nom_volumes=$(kubectl get  deployment dep-emptydir -o jsonpath='{.spec.template.spec.volumes[0].name}' 2>/dev/null)
if [[ "$nom_volumes" == "mon-volume-empty-dir"  ]]; then 
    echo  -e "Nom du volume ? ${GREEN} OK  ${ENDCOLOR}"
else 
    echo  -e "Nom du volume ? ${RED} KO  ${ENDCOLOR}"
    echo  -e "\t ${RED} nom trouvé:  $nom_volumes  ${ENDCOLOR}"
    exit 1 
fi 


type_volume=$(kubectl get  deployment dep-emptydir -o jsonpath='{.spec.template.spec.volumes[0].emptyDir}' 2>/dev/null)
if [[ "$type_volume" == "{}"  ]]; then 
    echo  -e "Type du volume ? ${GREEN} OK  ${ENDCOLOR}"
else 
    echo  -e "Type du volume ? ${RED} KO  ${ENDCOLOR}"
    echo  -e "\t ${RED} nom trouvé:  $type_volume  ${ENDCOLOR}"
    exit 1 
fi 

conteneur1_nb_volume_mount=$(kubectl get  deployment dep-emptydir -o jsonpath='{.spec.template.spec.containers[?(@.name == "conteneur1")].volumeMounts[*].name}' |wc -w 2>/dev/null)
if [[ "$conteneur1_nb_volume_mount" == "1"  ]]; then 
    conteneur1_name_volume_mount=$(kubectl get  deployment dep-emptydir -o jsonpath='{.spec.template.spec.containers[?(@.name == "conteneur1")].volumeMounts[0].name}' 2>/dev/null)
    if [[ "$conteneur1_name_volume_mount" == "mon-volume-empty-dir"  ]]; then 
        conteneur1_mountpath_volume_mount=$(kubectl get  deployment dep-emptydir -o jsonpath='{.spec.template.spec.containers[?(@.name == "conteneur1")].volumeMounts[0].mountPath}' 2>/dev/null)
        if [[ "$conteneur1_mountpath_volume_mount" == "/tmp/test"  ]]; then 
            echo  -e "montage volume sur conteneur1 ? ${GREEN} OK  ${ENDCOLOR}"
        else
            echo  -e "montage volume sur conteneur1  ${RED} KO  ${ENDCOLOR}"
        fi
    else
        echo  -e "montage volume sur conteneur1  ${RED} KO  ${ENDCOLOR}"
    fi
else 
    echo  -e "montage volume sur conteneur1  ${RED} KO  ${ENDCOLOR}"
fi 


conteneur2_nb_volume_mount=$(kubectl get  deployment dep-emptydir -o jsonpath='{.spec.template.spec.containers[?(@.name == "conteneur2")].volumeMounts[*].name}' |wc -w 2>/dev/null)
if [[ "$conteneur2_nb_volume_mount" == "1"  ]]; then 
    conteneur2_name_volume_mount=$(kubectl get  deployment dep-emptydir -o jsonpath='{.spec.template.spec.containers[?(@.name == "conteneur2")].volumeMounts[0].name}' 2>/dev/null)
    if [[ "$conteneur2_name_volume_mount" == "mon-volume-empty-dir"  ]]; then 
        conteneur2_mountpath_volume_mount=$(kubectl get  deployment dep-emptydir -o jsonpath='{.spec.template.spec.containers[?(@.name == "conteneur2")].volumeMounts[0].mountPath}' 2>/dev/null)
        if [[ "$conteneur2_mountpath_volume_mount" == "/tmp/test2"  ]]; then 
            echo  -e "montage volume sur conteneur2 ? ${GREEN} OK  ${ENDCOLOR}"
        else
            echo  -e "montage volume sur conteneur2  ${RED} KO  ${ENDCOLOR}"
        fi
    else
        echo  -e "montage volume sur conteneur2  ${RED} KO  ${ENDCOLOR}"
    fi
else 
    echo  -e "montage volume sur conteneur2  ${RED} KO  ${ENDCOLOR}"
fi 
