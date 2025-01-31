

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
- Namespace: **default**

 <li><h3> ex3 </h3></li>
Créer un pod avec les spécifications suivantes: 

- Nom du pod:  **podinitcontainer**
- nombre de Conteneur:  **1**
- nombre initConteneur: **1**
- Nom du conteneur1: **conteneur1**
- image du conteneur1:  **nginx:1.27.3**
- Nom init Conteneur1: **initconteneur**
- Image init Conteneur1: **busybox**
- Commande  de l'init  conteneur: **["sleep","10"]**
- Nampespace:  **default** 

 <li><h3> ex4 </h3></li>
Executer le fichier ex4.sh puis efectuer les opérations  suivantes

- Mettre les logs du pod "**pod1**" dans le fichier /tmp/logPod1
- Mettre le nombre de conteneur  dans le fichier /tmp/nbConteneurPod1
- Supprimer le pod "**pod1**" 
</ol>





