

<ol>
  <li><h3>ex1</h3></li>
Creer les ressources  ex1.yaml puis créer les networkpolicies suivantes: 

- blockall:  dans le namespace prod  pour n'autoriser aucun flux entrant et  sortant
- allow-mon-app:  qui autorise tout flux entrants dans le namespace dev **uniquement** sur les pods du deploiement nginx-dev. Vous pouvez rajouter toutes règles qui pourrait être necessaire.
- allow-monitoring: qui autorise **UNIQUEMENT** 
      - Le deploiement **nginx-dev**  du namepsace **dev** a communiquer avec le deploiement **nginx-monitoring** du namespace **monitoring** 
      - Tout les pods provenant des namespaces ayant pour label **allow-monitoring: true**    


 <li><h3>ex2</h3></li>
- Créer le namespace ex2 
- Déployer deux pods frontend et backend avec l'image nginx dans le namespace ex2
- Créer la networkPolicy front-to-back
  - Pour que seul le backend et le frontend puisse communiquer sur le port 80 uniquement
  - Le port 53 soit ouvert sur toutes les adresses. 

</ol>






