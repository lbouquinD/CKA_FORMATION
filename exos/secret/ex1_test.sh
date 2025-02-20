#!/bin/bash


RED="\e[31m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"



# verif job 
username=$(kubectl get secret test-secret  -ojsonpath='{.data.username}' |base64 -d 2>/dev/null)
password=$(kubectl get secret test-secret  -ojsonpath='{.data.password}' |base64 -d 2>/dev/null)
uneautrecle=$(kubectl get secret test-secret  -ojsonpath='{.data.uneautrecle}' |base64 -d 2>/dev/null)
echo -e "[ TEST secret  test-secret ]"
if [[ "$username" == "Us2R"  ]]; then 
  echo -e "\t username ${GREEN}OK${ENDCOLOR}"
else
  echo -e "\t username:  ${RED}KO${ENDCOLOR}" 
  echo -e "\t \t ${RED} username: $username ${ENDCOLOR}" 
fi
if [[ "$password" == "unPassordpresquepassecurise"  ]]; then 
  echo -e "\t password ${GREEN}OK${ENDCOLOR}"
else
  echo -e "\t password:  ${RED}KO${ENDCOLOR}" 
  echo -e "\t \t  ${RED} password: $password ${ENDCOLOR}" 
fi
if [[ "$uneautrecle" == "Et vero introrsum spiritu velariis."  ]]; then 
  echo -e "\t uneautrecle ${GREEN}OK${ENDCOLOR}"
else
  echo -e "\t uneautrecle:  ${RED}KO${ENDCOLOR}" 
  echo -e "\t \t  ${RED} uneautrecle: $uneautrecle ${ENDCOLOR}" 
fi
