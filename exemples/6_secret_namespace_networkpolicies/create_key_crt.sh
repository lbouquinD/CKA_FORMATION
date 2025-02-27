#!/bin/sh 
# Générer la clé privée
openssl genrsa -out /tmp/private.key  4096

# Générer le certificat autosigné
openssl req -x509 -new -nodes -key /tmp/private.key -days 365 -out /tmp/public.crt \
    -subj "/C=FR/ST=FRANCE/L=VotreVille/O=Daveo/OU=VotreUnite/CN=toto.fr"