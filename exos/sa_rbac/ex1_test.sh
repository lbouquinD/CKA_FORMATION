#!/bin/bash


RED="\e[31m\e[1m"
GREEN="\e[32m\e[1m"
ENDCOLOR="\e[0m"
BLUE="\e[34m\e[1m"



exist_sa=$(kubectl  get sa  exserviceaccount -ojsonpath='{.metadata.name}' 2>/dev/null)
if [[ "$exist_sa" == "exserviceaccount"  ]]; then
    echo -e "Compte de service  exserviceaccount existe ? ${GREEN} OK ${ENDCOLOR}" 
else
    echo -e "Compte de service  exserviceaccount existe ? ${RED} KO ${ENDCOLOR}"
    exit 1
fi 
