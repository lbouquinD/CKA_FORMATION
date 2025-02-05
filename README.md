
# Prérequis:  
<ol>
  <li><h3>Création de la Vm de provisionnement:  </h3></li>
  Se rendre dans les playground de cloud guru et créer une VM. avec les caractéristiques suivantes: </br>
    Taille Small </br>
    Distribution:  Ubuntu </br>
    Tag:  le nom de la Vm souhaité </br>
  <img src="md-picture/create_provisioner.png"
     alt="create_provisionner" /></img>
  <img src="md-picture/create_provisionedetails.png"
     alt="create provisionner" /></img>
</br>

  <li><h3> Récupération des sources </h3> </li>
    Se connecter sur la VM  précédemment créée et suivez les instructions.  Cette Vm a une période de validité de 2 semaines. A chaque fois que vous la démarrée la période est reconduite de 2 semaines. </br>
    Récupérer les sources comme suit: 
    <pre> 
     wget wget https://github.com/lbouquinD/CKA_FORMATION/archive/refs/tags/0.0.1.tar.gz 
     tar -xvf 0.0.1.tar.gz  
     cd CKA_FORMATION-0.0.1
    </pre>
</br>

# Instanciation des cluster :  EKS 

Ce projet a pour objectif  d'installer un cluster kubernetes en mode "On premise" sous aws  à l'aide de cloud guru
  <img src="md-picture/CKA_ARCHI.png"
     alt="create_provisionner" /></img>


<ol>




<li><h3> Instanciation de l'instance AWS  sur lequel va être provisionner l'ensembles des VM </h3></li>

<img src="md-picture/create_aws_instance2.png"
     alt="create provisionner " />

Récupérer l'access  key  id et  la Secret Access Key.  
L'environnement est  disponible pendant 4h renouvelable une fois  






  <li><h3> Installation de l'environnement </h3></li>
  Lancer les scripts  <pre>./1-installPackages.sh #  installation des dépendances ( awscli et  terraform ) </pre>  et  <pre>./2-initK8sCluster.sh # Installatiion des VMs/du cluster </pre> sur <b><i>ma_vm</i></b></br>
  Lors de l'execution du  2 ème script il vous sera demandé les clés AWS de l'étape précédente  </br>
  1. Choisissez entre les options  proposées:  <br>
  <pre>       1. Option on_premise:  installe uniquement les VMs sur aws et  configure le tunel ssh pour accéder au différentes VMs  </pre>
  <pre>       2. Verion EKS:  Installe directement un cluster kubernetes sur aws </pre>
  Laisser les champs  suivants à None. La configuration se fait par terraform
</br>Default region name 
</br>Default output format </br>
<b></b>$\color{red}{\textsf{ 💥 Ne pas lancer à la fois eks et on premise. Ceci aura pour effet de détruire votre environnement temporraire aws: trop de Vms créées  }}$</b>
</ol>

# Instanciation des cluster :  GKE


<ol>




<li><h3> Instanciation de l'instance GCP  sur lequel va être provisionner le  cluster GKE </h3></li>

<img src="md-picture/create_gcp_instance2.png"
     alt="create provisionner " />








  <li><h3> Installation de l'environnement </h3></li>
  Lancer les scripts  <pre>./1-installPackages.sh #  installation des dépendances ( awscli et  terraform ) </pre>  et  <pre>./2-initK8sCluster.sh # Installatiion des VMs/du cluster </pre> sur <b><i>ma_vm</i></b></br>
    </br>
Choisissez l'option  <b>3. Version GKE</b> Puis suivre les instructions suivantes: 
<ol>
<li>
Choisissez l'option 1 ( On modifie la configuration )  </br></br> 
<pre>

Pick configuration to use:
 [1] Re-initialize this configuration [formation-ckad] with new settings 
 [2] Create a new configuration
 [3] Switch to and re-initialize existing configuration: [default]
</pre>

</li>
<li>
Choisissez l'option 2 se connecter avec un nouvel utilisateur 
<pre> 

Select an account:
 [1] cloud_user_p_ca6d9a1d@linuxacademygclabs.com
 [2] Sign in with a new Google Account
 [3] Skip this step
Please enter your numeric choice: 

</pre>

<li> 
Copier le lien sur le navigateur ou vous êtes connecter sur la platforme GCP et récupéré le token: 
<pre>
Go to the following link in your browser, and complete the sign-in prompts:

    https://accounts.google.com/o/oauth2/auth?response_type=code&client_id=32555940559.apps.googleusercontent.com&redirect_uri=https%3A%2F%2Fsdk.cloud.google.com%2Fauthcode.html&scope=openid+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.email+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcloud-platform+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fappengine.admin+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fsqlservice.login+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcompute+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Faccounts.reauth&state=KkorsXT7pPw5loKJg9irS8TURAN6in&prompt=consent&token_usage=remote&access_type=offline&code_challenge=IX1U4myVG71cr3OJHDJIfVhBPqFlEVI_rWlQ1AtV5K0&code_challenge_method=S256
</br>
Once finished, enter the verification code provided in your browser: 4/0ASVgi3I6peRwmlGuRd17WuNT7Q0pRuUiwNvoM6JRfa-u1b9AVRblR3m31SYa7MeJ08t1sg

</pre>



<ol><li>
 Copie du lien
<img src="md-picture/gcp_connexion.png"
     alt="create provisionner " />
</li>
<li>
Cliquer sur continue
<img src="md-picture/gcp_autorisation_1.png"
     alt="create provisionner " />
</li>

<li>
Cliquzer sur allow 
<img src="md-picture/gcp_autorisation_2.png"
     alt="create provisionner " />
</li>

<li>
Cliquer sur copy
<img src="md-picture/gcp_token.png"
     alt="create provisionner " />
</li>
</ol>


</li>
</ol>

