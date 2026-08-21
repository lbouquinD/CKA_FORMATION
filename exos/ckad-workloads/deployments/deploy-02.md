# deploy-02 — Scale et inventaire

Niveau 1 — 15 minutes

Contexte : namespace `ckad-deploy-02`.

Préparez le scénario avec `./lab.sh start deploy-02`.

1. Passez le Deployment `catalog` à 5 réplicas.
2. Attendez la fin du déploiement.
3. Écrivez dans `/tmp/ckad-deploy-02.txt` une ligne sans en-tête au format
   `NOM READY UP-TO-DATE AVAILABLE`, obtenue depuis la ressource Deployment.

Les cinq réplicas doivent être disponibles.
