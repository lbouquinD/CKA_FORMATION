# sts-01 — Identité réseau stable

Niveau 2 — 25 minutes

Contexte : namespace `ckad-sts-01`.

Créez :

1. un Service headless `web-headless` (`clusterIP: None`) sélectionnant
   `app=stateful-web`, port `80`;
2. un StatefulSet `stateful-web`, `serviceName: web-headless`, 3 réplicas,
   sélecteur et template `app=stateful-web`;
3. un conteneur `nginx` avec l'image `nginx:1.27.3` et le port `80`.

Les Pods `stateful-web-0`, `stateful-web-1` et `stateful-web-2` doivent être
disponibles.
