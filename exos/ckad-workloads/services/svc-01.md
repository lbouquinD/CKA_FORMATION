# svc-01 — Service ClusterIP

Niveau 1 — 15 minutes

Contexte : namespace `ckad-svc-01`.

Créez :

1. un Deployment `web` de 2 réplicas :
   - labels et sélecteur `app=web`;
   - conteneur `nginx`, image `nginx:1.27.3`, port `80`;
2. un Service `web` :
   - type `ClusterIP`;
   - sélecteur `app=web`;
   - port `80` vers le `targetPort` `80`.

Les deux réplicas doivent être disponibles. Le Service doit avoir des
Endpoints prêts.
