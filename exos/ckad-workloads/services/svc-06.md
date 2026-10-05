# svc-06 — Service sans sélecteur

Niveau 2 — 20 minutes

Contexte : namespace `ckad-svc-06`.

Un service externe n'est pas dans le cluster. Exposez-le quand même.

Créez :

1. un Service `legacy-db` :
   - type `ClusterIP`;
   - **sans sélecteur**;
   - port `5432`, `targetPort` `5432`;
2. une ressource Endpoints du **même nom** `legacy-db` :
   - adresse `192.0.2.10`;
   - port `5432`.

Aucun Pod n'est attendu. Sur un cluster récent, `kubectl` peut afficher un
avertissement de dépréciation : gardez la ressource Endpoints `v1`.
