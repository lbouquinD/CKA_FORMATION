#!/bin/bash
current_namespace=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)

while true; do 
  echo " TEST:  $(date)" 
  # Vérification des permissions sur les Pods
  echo "Pods:"
  echo "  Lecture: $(check_permissions pods get \"true\" $current_namespace)"
  echo "  Écriture: $(check_permissions pods create \"true\" $current_namespace)"
  echo "  Logs: $(check_permissions pods logs \"true\" $current_namespace)"

  # Vérification des permissions sur les Secrets
  echo "Secrets:"
  echo "  Liste (global): $(check_permissions secrets list  \"true\" $current_namespace)"
  echo "  Lecture (local): $(check_permissions secrets get  \"true\" $current_namespace)"
  echo "  Création (local): $(check_permissions secrets create  \"true\" $current_namespace)"

  # Vérification des permissions sur les Namespaces
  echo "Namespaces:"
  echo "  Liste: $(check_permissions namespaces list false)"
  echo "  Création: $(check_permissions namespaces create false)"
  # ... ajoutez d'autres vérifications pour d'autres ressources
  sleep 5 
done 