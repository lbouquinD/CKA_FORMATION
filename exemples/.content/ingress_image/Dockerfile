FROM nginx:1.27.4

# Copie du fichier index.html
COPY index.html /usr/share/nginx/html/

# Copie du fichier de configuration nginx
COPY nginx.conf /etc/nginx/nginx.conf

CMD ["nginx", "-g", "daemon off;"]