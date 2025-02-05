#!/bin/bash

dir=""
while true; do
  echo "Choisissez une option :"
  echo "1. Option on_premise"
  echo "2. Version eks"
  echo "3. Vertion GKE"
  read choix

  case $choix in
    1)
      echo "Vous avez choisi l'option on_premise."
      terraform_dir="on_prem_aws"
      break ;;
    2)
      echo "Vous avez choisi la version eks."
      terraform_dir="eks"
      aws configure
      rm $terraform_dir/terraform.tfstate
      break ;;
    3)
     gcloud config configurations activate  default
     yes | gcloud config configurations delete formation-ckad 2>/dev/null 
     gcloud config configurations create formation-ckad
     gcloud init
     gcloud auth application-default login
     exit 0
     ;; 
    *)
      echo "Choix invalide. Veuillez entrer 1 ou 2."
      ;;
  esac
done

terraform  -chdir=$terraform_dir init  
terraform  -chdir=$terraform_dir apply -auto-approve


if [[ "$terraform_dir" == "eks" ]]; then
   aws eks --region $(terraform -chdir=$terraform_dir output -raw region) update-kubeconfig     --name $(terraform  -chdir=$terraform_dir output -raw cluster_name) 
fi

# aws eks --region us-west-2  update-kubeconfig     --name cka_formation_k8s
