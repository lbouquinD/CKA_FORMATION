

<ol>
  <li><h3>ex1</h3></li>
Créer un job avec les spécifications suivantes: 

- Nom du Job:  **ex1job**
- Nom du conteneur: **premier-job**
- image du conteneur:  **busybox**
- command: ["/bin/sh","-c","echo bonjour depuis mon premier job;  sleep 10"]
- restartPolicy:  Never
- Nampespace:  **default**  


 Exercice 2 : Création d'un CronJob

Créer un CronJob avec les spécifications suivantes :

- Nom du CronJob: **mon-cronjob**
- Schedule: **S'exécuter tout les dimanche à 10h03**
- Nom du conteneur: **task-exec**
- Image du conteneur: **alpine**
- command: **["/bin/sh" ,"-c" ,"echo \"Tâche exécutée à $(date)\""]**
- restartPolicy: **OnFailure**
- Namespace: **default**

 <li><h3> ex3 </h3></li>
Lancer le script ex3.sh et créer le job test à partir du cronjob ex3cron 


 




