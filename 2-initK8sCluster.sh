#!/bin/bash 

aws configure
terraform  -chdir=init_infrak8s init  
terraform  -chdir=init_infrak8s apply -auto-approve