# svc-07 — Service headless

Niveau 2 — 15 minutes

Contexte : namespace `ckad-svc-07`.

Créez :

1. un Deployment `members` de 2 réplicas :
   - labels et sélecteur `app=members`;
   - conteneur `app`, image `busybox:1.36`, commande `sleep 3600`;
2. un Service headless `members` :
   - `clusterIP: None`;
   - sélecteur `app=members`;
   - port `80`.

Les deux réplicas doivent être disponibles. Le Service doit publier une
adresse par Pod.
