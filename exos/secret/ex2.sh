#!/bin/bash  

RED="\e[31m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"

kubectl get namespace dgsi 2>/dev/null | grep -q "dgsi" || kubectl create namespace dgsi
sleep 3 

yaml=$(cat << EOF

---
apiVersion: v1
kind: Secret
metadata:
  name: secret-operation
  namespace: dgsi
data:
  mot-de-passe-du-boss: "cGFzc3dvcmQ6IG1vdXNzaW1vbi10cm9waXF1ZQ==" 
  numero-de-l-agent-007: "bnVtZXJvOiAwMDctc2VjcmV0" 
  code-du-coffre-fort-au-tresor: "Y29kZTogbW90LWRlLXBhc3NlLXNlY3Jl" 

---
apiVersion: v1
kind: Secret
metadata:
  name: secret-projet
  namespace: dgsi
data:
  nom-de-code-du-projet-top-secret: "bm9tOiBwcm9qZXQtdG9wLXNlY3JldA==" 
  equipe-de-genies: "ZXF1aXBlOiBxdWVsZXVzLWNxdWktdm9udC1yZXZlbGxlci1sZS1tb25kZQ==" 
  budget-astronomique: "YnVkZ2V0OiBwb3VyLWNvbnRydWxldXIgbGEgZG9tZSBkZSBtb24gY29uZGU=" 
  date-du-debut-des-hostilites: "ZGF0ZTogbW9uciAxNSBqb2luIDIwMjQ=" 
  planque-pour-la-reunion-secrete: "cGxhbnF1ZTogbW9udGFnbmUtc2VjcmV0ZQ==" 

---
apiVersion: v1
kind: Secret
metadata:
  name: secret-agent
  namespace: dgsi
data:
  nom-de-l-agent-trop-cool: "bm9tOiBhZ2VudC10cm9wLWNvb2w=" 
  date-de-naissance-mysterieuse: "ZGF0ZTogMDAvMDAvMDAwMA==" 
  numero-de-matricule-illisible: "bnVtZXJvOiB4eHh4eHh4eHg=" 
  adresse-de-la-planque: "YWRyZXNzZTogbW9udGFnbmUtc2VjcmV0ZQ==" 
  numero-de-telephone-a-ne-pas-divulguer: "bnVtZXJvOiA2NjYtNjY2LTY2NjY="
  nom-de-code-du-super-espion: "bm9tOiBzdXBlci1lc3Bpb24=" 
  specialite-de-l-agent-ninja: "c3BlY2lhbGl0ZTogbmluamE=" 

---
apiVersion: v1
kind: Secret
metadata:
  name: secret-contact
  namespace: dgsi
data:
  nom-du-contact-suspect: "bm9tOiBjb250YWN0LXN1c3BlY3Q="
  numero-de-telephone-du-contact-a-surveiller: "bnVtZXJvOiA3NzctNzcwLTc3Nz==" 

---
apiVersion: v1
kind: Secret
metadata:
  name: secret-lieu
  namespace: dgsi
data:
  adresse-du-lieu-tenu-secret: "YWRyZXNzZTogbW9udGFnbmUtc2VjcmV0ZQ==" 
  code-d-acces-pour-les-inities: "Y29kZTogc2VzYW1lLW91dmVydC10b2k=" 
  plan-du-lieu-ultra-secret: "cGxhbjogdHJlc29yLXBldXgtY2FjaGU=" 
  instructions-de-securite-pour-les-pros: "aW5zdHJ1Y3Rpb25zOiBwYXMtZGUtcGFz" 
EOF
)
{
# Apply the YAML using kubectl
kubectl apply -f - << EOF
$yaml
EOF
} 1>/dev/null
echo  -e "${GREEN} Script exécuté avec succès ${ENDCOLOR}"