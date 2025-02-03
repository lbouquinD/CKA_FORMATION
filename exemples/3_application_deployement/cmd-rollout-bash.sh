#  Recupération de l'historique des version de déploiement
kubectl rollout history  deployment


# Anuler les dernières modifications  sur le déploiement busybox-sleep-deployment [  fonctionne également avec les daemonset et  les statefulsets ]
kubectl rollout undo deployment busybox-sleep-deployment





# logs sur un conteneur (-c  optionnel. Si on le met pas c'est les logs du dernier conteneur déclaré) ici  init   et  on veux les logs avant le redémarrage --previous. Si je veu les logs actuel  on enlève le --previous 
kubectl logs formation-ckad-pod-with-init-container -c init  --previous 