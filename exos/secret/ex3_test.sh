#!/bin/bash


RED="\e[31m\e[1m"
GREEN="\e[32m\e[1m"
ENDCOLOR="\e[0m"
BLUE="\e[34m\e[1m"
echo -e "${BLUE}\n\t [TEST monpremiersecrettls] \n${ENDCOLOR}"
typesecret=$(kubectl get secret  -o yaml monpremiersecrettls -o jsonpath='{.type}' 2>/dev/null)
if [[ "$typesecret" == "kubernetes.io/tls"  ]]; then 
  echo -e " Le type de secret  est  correct ${GREEN}OK${ENDCOLOR}"
else
  echo -e " Le type de secret est  correct  ${RED}KO${ENDCOLOR}" 
  echo -e "\t ${RED} type de secret  trouvé: $typesecret -> secret souhaité tls ${ENDCOLOR}" 
fi


base64cle=$(cat /tmp/ex3secret/private.key |base64 |tr -d "\n")
base64crt=$(cat /tmp/ex3secret/public.crt |base64 |tr -d "\n")

tlskey=$(kubectl get secret  -o yaml monpremiersecrettls -o jsonpath='{.data.tls\.key}' 2>/dev/null)
tlscrt=$(kubectl get secret  -o yaml monpremiersecrettls -o jsonpath='{.data.tls\.crt}' 2>/dev/null)


if [[ "$base64cle" == "$tlskey"  && "$base64crt" ==  "$tlscrt" ]]; then 
  echo -e " la clé et/ou le certificat sont correct ${GREEN}OK${ENDCOLOR}"
else
  echo -e " La cle ou/et le certificat sont incorrect  ${RED}KO${ENDCOLOR}" 
fi