# CKA_FORMATION
 
Ce projet a pour objectif  d'installer un cluster kubernetes en mode "On premise" sous aws  à l'aide de cloud guru



<ol>
  <li><h3>Création de la Vm de provisionnement:  </h3></li>
  Se rendre dans les playground de cloud guru et  cvréer une VM. avec les caractéristique suivantes: </br>
    Taille Small </br>
    Distribution:  Ubuntu </br>
    Tag:  le nom de la Vm souhaité </br>
  <img src="md-picture/create_provisioner.png"
     alt="create_provisionner"
     style="float: left; margin-right: 10px;" />
     <img src="md-picture/create_provisioner2.png"
     alt="create provisionner "
     style="float: left; margin-right: 10px;" />

---
  <li><h3> Récupération des sources </h3> </li>
    Se connecter sur la VM  précédemment créé et suivez les instructions.  Cette Vm a une période de validité de 2  semaine. A chaque fois que vous la démarrer  la periode est  reconduite de 2 semaines. Cloner  ce repository  git 
---
<li><h3> Instanciation de l'instance AWS  sur lequel va être provisionner l'ensembles des VM </h3></li>

<img src="md-picture/create_aws_instance.png"
     alt="create provisionner "
     style="float: left; margin-right: 10px;" />

Récupérer l'access  key  id et  la Secret Access Key.  
L'environnement est  disponible pendant 4h renouvelable une fois  






  <li><h3> Installation de l'environnement </h3></li>
  Lancer les scripts  ./1-installPackages.sh  et  ./2-initK8sCluster.sh
  lors de l'execution du  2 ème script il vous sera demander  les clé aws de l'étape précédente  </br> Laisser les champs  suivant a None. La configuration se fait par terraform
Default region name </br>
Default output format </br>


</ol>