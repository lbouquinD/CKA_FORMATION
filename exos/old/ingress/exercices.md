<ol>
  <li><h3>ex1</h3></li>
Lancer le script ex1.sh et  créer l'ingress avec les spécifications suivantes. 

- Namespace:  **exoingress**
- Nom: **exingress**
- Host  **toto.fr** 
- ingressClassName: **classexercice***
- Doit uniquement répondre sur **toto.fr/monappA**  sur le service **svctoexpose-a**  ( ne doit pas répondre sur toto.fr/monappA/* )
-  Doit repondre dsur l'uti et  toute les sous path  de **toto.fr/monAppB** sur le service **svctoexpose-b**
- doit être sécurisé en tls  ( secret  tls déjà créé sous le nom  **tototls**)

Astuces:  bien regarder les services associés: 
</ol>