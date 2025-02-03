FROM ubuntu:22.04

# Installer les outils réseau
RUN apt-get update && apt-get install -y netcat ping host

# Copier le script run.sh dans le conteneur
COPY run.sh /usr/local/bin/

# Exposer le port si nécessaire (ajuster si besoin)
EXPOSE 8080

# Définir les variables d'environnement par défaut (si nécessaire)
ENV NOM_APP="mon_application"
ENV NOM_POD="default_pod"

# Commandes à exécuter au démarrage du conteneur
CMD ["/usr/local/bin/run.sh"]
