

<ol>
  <li><h3>ex1</h3></li>
Créer un pod avec les spécifications suivantes: 

- Nom du  pod:  **ex1pod**
- Nom du conteneur: **premier-pod**
- image du conteneur:  **nginx:1.27.3**
- Nampespace:  **default**  


 <li><h3> ex2 </h3></li>
Créer un pod avec les spécifications suivantes: 

- Nom du  pod:  **ex2pod**
- nombre de Conteneur:  **2**
- Nom du conteneur1: **conteneur1**
- image du conteneur1:  **nginx:1.27.3**
- Nom du conteneur2: **conteneur2**
- Image du conteneur2: **busybox**
- Commande  du  conteneur2: **["sleep","1000"]**
- Nampespace:  **default** 

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





