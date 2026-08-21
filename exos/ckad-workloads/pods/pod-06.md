# pod-06 — CrashLoopBackOff

Niveau 3 — 15 minutes

Contexte : namespace `ckad-pod-06`.

Préparez le scénario avec `./lab.sh start pod-06`.

Le Pod `looping-worker` redémarre continuellement. Diagnostiquez-le avec les
commandes Kubernetes adaptées, puis corrigez-le.
Les champs de démarrage d'un Pod étant immuables, une recréation avec le même
nom peut être nécessaire.

Contraintes finales :

- conserver `busybox:1.36` et le conteneur `worker`;
- la commande doit exécuter `sleep 3600`;
- conserver `restartPolicy: Always`;
- le Pod doit être `Ready` et ne plus redémarrer en boucle.
