#!/bin/bash


RED="\e[31m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"



existJob=$(kubectl get job test 2>/dev/null |wc -l)
if [[ $existJob -gt 0 ]]; then
  echo  -e "Le job test exist ${GREEN} OK ${ENDCOLOR}"
else
  echo  -e "Le job test exist ${RED} KO ${ENDCOLOR}"
  exit 1
fi  



jobCreateByCron=$(kubectl get job test  -o jsonpath='{.metadata.annotations.cronjob\.kubernetes\.io/instantiate}')
if [[ "$jobCreateByCron" == "manual" ]]; then 
    echo  -e "Le job test  est  créé  par  ex3cron ${GREEN} OK ${ENDCOLOR}"
else 
    echo  -e "Le job test  est  créé  par  ex3cron ${RED} KO ${ENDCOLOR}"
    echo  -e " Le cron test n'as pas été créé a partir du cron demandé " 
fi