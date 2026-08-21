<ol>
  <li><h3>ex1</h3></li>
Créer un pod avec les spécifications suivante. 

- Nom du  pod:  **test**
- Nom du conteneur: **test**
- image du conteneur:  **nginx:1.27.3**
- Nampespace:  **default**  

Exposer ce pod avec les spécification suivantes: 

-  nom du service: **test-svc-ex1**
-  port d'écoute: **80**
-  Port du conteneur: **80** 
-  type:  ClusterIP


 <li><h3> ex2 </h3></li>
Executer le fichier ex2.sh puis effectuer les operations suivantes:  

Créer les 2 services suivants: 

- nom: **exosvc21**
- type: **Nodeport**
- port d'écoute: **80**
- Port du conteneur: **8124** 
- NodePort: **31258** 
- Doit exposer le deploiement: **dep-ex-service-2**


- nom: **exosvc22**
- type: **loadBalancer**
- port d'écoute: **80**
- Port du conteneur: **9090** 
- Doit exposer le deploiement: **dep-ex-service-3**

</ol>