#!/bin/bash

$dir = ""
while true; do
  echo "Choisissez une option :"
  echo "1. Option on_premise"
  echo "2. Version eks"

  read choix

  case $choix in
    1)
      echo "Vous avez choisi l'option on_premise."
      $terraform_dir="on_prem_aws"
      break ;;
    2)
      echo "Vous avez choisi la version eks."
      $terraform_dir="eks"
      break ;;
    *)
      echo "Choix invalide. Veuillez entrer 1 ou 2."
      ;;
  esac
done

aws configure
terraform  -chdir=$terraform_dir init  
terraform  -chdir=$terraform_dir apply -auto-approve


if [[ "$terraform_dir" == "eks" ]]; then
   aws eks --region $(terraform -chdir=$terraform_dir output -raw region) update-kubeconfig     --name $(terraform  -chdir=$terraform_dir output -raw cluster_name) 
fi
