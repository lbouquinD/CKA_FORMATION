<ol>
  <li><h3>ex1</h3></li>

Créer un deploiement avec un volume de type **EmptyDir**

- nom du deploiement: **dep-emptydir**
- nom conteneur1: **contreneur1**
- nom conteneur2 : **conteneur2**
- nombre de replicas: **1**
- image conteneur1:  **nginx:1.27.3**
- image conteneur2:   **wardsco/sleep**
- nom du volume: **mon-volume-empty-dir**
- montage: 
    - **/tmp/test sur conteneur1**
    - **/tmp/test2  sur conteneur2**

 <li><h3> ex2 </h3></li>
Executer le fichier ex2.sh puis effectuer les operations suivantes:  

- creer un pod **ex2-hostpath**
    - image  conteneur1:  **nginx1.27.3**
    - nom conteneur1: **conteneur1**
    - nom du volume: **mon-volume-hostpath**
    - type volume:  **hostpath**
    - path du hostpath: **/tmp/ex2hostpath**
    - hostpathtype:**DirectoryOrCreate**
    - montage:  
        -   **/tmp sur le conteneur1**
</ol>

 <li><h3> ex3 </h3></li>
Executer le fichier ex3.sh puis effectuer les operations suivantes:  


1] Creer le pvc suivant: 
- nom du pvc: **ex3pvc**
- demande de stockage: **1Mi**
- storageclass:  **local-path**
- accessmode:  **ReadWriteOnce**

2] creer un pod  suivant: 
    - nom du pod: **ex3-pod-pvc**
    - image  conteneur1:  **nginx1.27.3**
    - nom conteneur1: **conteneur1**
    - nom du volume: **mon-volume-pvc**
    - type volume:  **PVC**
    - doit utiliser le pvc créeer précédemment (ex3pvc) 
    - montage:  
        -   **/tmp/stockage sur le conteneur1**
</ol>