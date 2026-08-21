DANS les exercices suivants il peu y avoir des networkpolicies supplémentaire a ajouter pour répondre aux conditions. 

<ol>
  <li><h3>ex1</h3></li>
Creer les ressources  ex1.yaml puis créer les networkpolicies suivantes: 

- blockall:  dans le namespace prod  pour n'autoriser aucun flux entrant et  sortant
- allow-mon-app:  qui autorise tout flux entrants dans le namespace dev **uniquement** sur les pods du deploiement nginx-dev. Vous pouvez rajouter toutes règles qui pourrait être necessaire.
- allow-monitoring: qui autorise **UNIQUEMENT** 
      - Le deploiement **nginx-dev**  du namepsace **dev** a communiquer avec tout les adresses sur le port 53 
      - Le deploiement **nginx-dev**  du namepsace **dev** a communiquer avec le deploiement **nginx-monitoring** du namespace **monitoring** 
      - Tout les pods ET namespace ayant pour label **allowmonitoring: autorise** a communiquer avec le deploiement **nginx-monitoring** du namespace **monitoring** 






