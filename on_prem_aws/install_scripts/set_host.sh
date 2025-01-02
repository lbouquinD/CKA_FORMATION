#!/bin/bash 


 # Supprimer les balises # BEGIN TERRAFORM, # END TERRAFORM et tout ce qui est entre elles
sudo sed -i '/# BEGIN TERRAFORM/,/# END TERRAFORM/{//!d}' /etc/hosts #supression de ce qu'il y a entre ces balises
sudo sed -i '/# BEGIN TERRAFORM/,/# END TERRAFORM/d'  /etc/hosts #supression des balises
sudo tee -a /etc/hosts < /tmp/hosts