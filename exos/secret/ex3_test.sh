#!/bin/bash


RED="\e[31m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"

typesecret=$(kubectl get secret  -o yaml monpremiersecrettls -o jsonpath='{.type}')
if [[ "$typesecret" == "kubernetes.io/tls"  ]]; then 
  echo -e "\t Le type de secret  est  correct ${GREEN}OK${ENDCOLOR}"
else
  echo -e "\t Le type de secret est  correct  ${RED}KO${ENDCOLOR}" 
  echo -e "\t \t ${RED} type de secret  trouvé: $typesecret -> secret souhaité tls ${ENDCOLOR}" 
fi


base64cle=$(cat /tmp/ex3secret/private.key |base64)
base64crt=$(cat /tmp/ex3secret/public.crt |base64)

tlskey=$(kubectl get secret  -o yaml monpremiersecrettls -o jsonpath='{.data.tls\.key}')
tlscrt=$(kubectl get secret  -o yaml monpremiersecrettls -o jsonpath='{.data.tls\.crt}')

if [[ "$base64cle" == "$tlskey"  && "$base64crt" ==  "$tlscrt" ]]; then 
  echo -e "\t la clé et/ou le certificat sont correct ${GREEN}OK${ENDCOLOR}"
else
  echo -e "\t La cle ou/et le certificat sont incorrect  ${RED}KO${ENDCOLOR}" 
fi