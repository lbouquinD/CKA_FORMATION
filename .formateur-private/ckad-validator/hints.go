package main

// Rappels des premiers parcours (pods à services), dont les contrôles sont
// déclarés sans noted(). Clé : "<exercice>|<catégorie>".
var legacyHints = map[string]string{
	// Pods
	"pod-01|ressource":     "Le Pod doit porter le nom demandé, dans le namespace de l'exercice. Vérifiez le contexte et le -n de votre commande.",
	"pod-01|configuration": "kubectl run accepte --image, --labels et --env. Un seul conteneur est attendu. Comparez image, label et variable avec kubectl get pod -o yaml.",
	"pod-01|disponibilité": "Attendez la condition Ready. kubectl describe pod montre les événements : image introuvable, erreur de démarrage...",

	"pod-02|annotation":   "kubectl annotate ajoute une annotation sans recréer le Pod. Les annotations sont dans metadata.annotations, à part des labels.",
	"pod-02|labels":       "kubectl label --overwrite remplace la valeur d'un label existant. Un label s'ajoute avec la même commande.",
	"pod-02|pod conservé": "Labels et annotations se modifient à chaud. Ne supprimez pas le Pod : son image et ses variables doivent rester celles d'origine.",

	"pod-03|liste avec labels": "kubectl get pods --show-labels ajoute la colonne LABELS. Redirigez la sortie brute vers le fichier demandé.",
	"pod-03|filtre":            "L'option -l filtre par label côté API. Seuls les Pods qui portent le label doivent apparaître dans le fichier.",
	"pod-03|yaml réutilisable": "kubectl get -o yaml inclut uid, resourceVersion et status. Générez le manifeste avec une commande impérative et --dry-run=client -o yaml.",

	"pod-04|configuration": "La commande se passe après -- avec kubectl run. Elle doit afficher l'environnement puis dormir. --env ajoute une variable par option.",
	"pod-04|logs":          "kubectl logs affiche la sortie standard du conteneur. Les variables n'y apparaissent que si la commande les imprime au démarrage.",
	"pod-04|disponibilité": "Un busybox qui termine sa commande s'arrête et redémarre. La commande doit finir par une attente durable.",

	"pod-05|sélecteur": "kubectl delete pods -l <label> supprime tous les Pods qui portent ce label, en une commande. Vérifiez la liste avec le même -l avant.",
	"pod-05|force":     "--force combiné à --grace-period=0 supprime sans attendre la période de grâce.",

	"pod-06|ressource":     "Le Pod doit porter le nom demandé, dans le namespace de l'exercice.",
	"pod-06|configuration": "kubectl run nomme le conteneur comme le Pod. Générez le YAML avec --dry-run=client -o yaml, renommez le conteneur, puis appliquez.",
	"pod-06|disponibilité": "Attendez la condition Ready. Une image mal orthographiée laisse le Pod en ErrImagePull.",

	"pod-07|métadonnées":   "Labels et annotations se déclarent sous metadata. Une clé d'annotation peut contenir un préfixe avec un slash.",
	"pod-07|ressources":    "requests et limits se posent dans le conteneur, sous resources. restartPolicy est un champ du spec du Pod.",
	"pod-07|disponibilité": "Une limit inférieure à la request est refusée. Attendez la condition Ready.",

	"pod-08|conteneurs":     "Deux conteneurs dans spec.containers, chacun avec son nom et sa commande. L'écrivain boucle avec une pause, le lecteur suit le fichier sans s'arrêter.",
	"pod-08|volume partagé": "Le volume emptyDir se déclare une fois dans spec.volumes. Chaque conteneur a son propre volumeMount qui le référence par son nom.",
	"pod-08|comportement":   "Le fichier doit exister et ne pas être vide côté lecteur. Vérifiez le chemin écrit par le writer et le chemin de montage.",
	"pod-08|disponibilité":  "Les deux conteneurs doivent rester actifs. Un conteneur qui termine sa commande rend le Pod NotReady.",

	"pod-09|initialisation": "Un init container se déclare sous spec.initContainers. Il s'exécute jusqu'au bout avant le démarrage des conteneurs principaux.",
	"pod-09|volume partagé": "L'init container et le conteneur principal montent le même emptyDir, chacun sur son propre chemin.",
	"pod-09|contenu servi":  "Le fichier écrit par l'init container doit se trouver là où nginx sert ses pages. Contrôlez son contenu depuis le conteneur web.",
	"pod-09|disponibilité":  "Un init container qui échoue laisse le Pod en Init:Error. kubectl logs -c <init> montre son erreur.",

	"pod-10|sonde readiness": "Une sonde httpGet vise un chemin servi et le port réellement écouté. Les sondes d'un Pod sont immuables : recréez le Pod.",
	"pod-10|sonde liveness":  "La liveness se déclare comme la readiness, avec son propre initialDelaySeconds. Une liveness en échec redémarre le conteneur.",
	"pod-10|disponibilité":   "kubectl describe pod affiche les échecs de sonde dans les événements. Le Pod passe Ready quand la readiness réussit.",

	"pod-11|configuration": "kubectl logs --previous montre la sortie du conteneur précédent. La commande d'un Pod est immuable : recréez-le avec le même nom.",
	"pod-11|stabilité":     "Après correction, le compteur de redémarrages repart de zéro sur le nouveau Pod. Il doit rester bas.",

	"pod-12|image et commande": "kubectl describe pod donne la raison de l'échec : image introuvable, commande invalide... command est une liste : le shell, son option, puis le script.",
	"pod-12|environnement":     "Une variable simple utilise value. La Downward API passe par valueFrom.fieldRef.fieldPath.",
	"pod-12|disponibilité":     "Image et commande sont immuables sur un Pod : supprimez-le puis recréez-le avec le même nom.",

	"pod-13|logs exportés":      "kubectl logs <pod> -c <conteneur> > fichier. Le chemin demandé est un fichier, pas un répertoire.",
	"pod-13|inventaire":         "-o custom-columns sélectionne les champs et --no-headers retire l'en-tête. --sort-by=.metadata.name trie par nom. Faites l'inventaire avant la suppression de l'étape 3.",
	"pod-13|suppression ciblée": "Supprimez le Pod par son nom. Le Pod ops-reporter doit continuer de tourner.",

	// ReplicaSets
	"rs-01|configuration": "Le sélecteur du ReplicaSet doit correspondre aux labels du template. kubectl create ne génère pas de ReplicaSet : partez d'un YAML de Deployment et changez le kind.",
	"rs-01|pods gérés":    "Le ReplicaSet compte les Pods qui portent son label. kubectl get pods -l <label> doit en montrer autant que de réplicas.",

	"rs-02|sélecteur":     "Le sélecteur d'un ReplicaSet est immuable. Supprimez puis recréez la ressource avec le nouveau sélecteur et le même label dans le template.",
	"rs-02|configuration": "Un ReplicaSet ne met pas à jour ses Pods existants. Après recréation, contrôlez image, nom du conteneur et réplicas disponibles.",

	"rs-03|mise à l'échelle": "kubectl scale --replicas modifie le nombre voulu. Attendez que les nouveaux Pods soient disponibles.",
	"rs-03|inventaire":       "Écrivez les noms actuels, un par ligne, triés. -o name ajoute le préfixe pod/ : utilisez une sortie sans préfixe.",
	"rs-03|auto-réparation":  "Supprimez un Pod du ReplicaSet : il en recrée un autre, sous un nouveau nom. Attendez le remplacement avant d'écrire l'inventaire.",

	// Deployments
	"deploy-01|configuration": "kubectl create deployment accepte --replicas et --port. Le nom du conteneur dérive de l'image : vérifiez-le dans le YAML.",

	"deploy-02|mise à l'échelle": "kubectl scale deployment --replicas, puis kubectl rollout status pour attendre la fin.",
	"deploy-02|inventaire":       "La ligne vient de kubectl get deployment, sans en-tête (--no-headers), avec les colonnes NAME READY UP-TO-DATE AVAILABLE. Retirez la colonne AGE.",

	"deploy-03|mise à jour":   "kubectl set image change l'image du template. L'annotation change-cause se pose sur le Deployment, avec kubectl annotate.",
	"deploy-03|disponibilité": "kubectl rollout status attend la fin du rollout. Les réplicas doivent tous être à jour et disponibles.",

	"deploy-04|révision restaurée": "kubectl rollout history montre les révisions et leur change-cause. kubectl rollout undo --to-revision revient à une révision précise.",
	"deploy-04|disponibilité":      "Après le retour arrière, attendez la fin du rollout.",
	"deploy-04|historique":         "Ne recréez pas le Deployment : ses anciens ReplicaSets forment l'historique.",

	"deploy-05|stratégie":     "strategy.type et strategy.rollingUpdate se déclarent dans le spec du Deployment, au même niveau que replicas. revisionHistoryLimit aussi.",
	"deploy-05|configuration": "Vérifiez le nom du conteneur, l'image, le label du sélecteur et le nombre de réplicas disponibles.",

	"deploy-06|image et démarrage": "Les événements du ReplicaSet et des Pods donnent la cause : image, commande... Retirez toute commande qui remplace celle de l'image.",
	"deploy-06|sonde":              "Une readiness HTTP doit viser un chemin servi et le port écouté par nginx.",
	"deploy-06|ressources":         "Les limits se posent dans le conteneur du template, sous resources. Une limit trop basse peut tuer le conteneur (OOMKilled).",
	"deploy-06|disponibilité":      "Corrigez toutes les causes, puis attendez la fin du rollout. kubectl rollout status signale un rollout bloqué.",

	"deploy-07|sélecteur":     "spec.selector d'un Deployment est immuable. Exportez le YAML, supprimez le Deployment, corrigez sélecteur et labels du template, puis recréez-le.",
	"deploy-07|configuration": "Après recréation, contrôlez nom du conteneur, image et réplicas disponibles.",

	"deploy-08|stable":     "Chaque Deployment sélectionne ses deux labels : app et track. Sans track dans le sélecteur, les deux Deployments se disputent les Pods.",
	"deploy-08|canary":     "Le canary porte le même app que le stable mais un autre track, avec sa propre image et son propre nombre de réplicas.",
	"deploy-08|inventaire": "Écrivez les noms des Deployments, un par ligne, triés, sans préfixe ni en-tête.",

	// DaemonSets
	"ds-01|configuration": "Un DaemonSet n'a pas de replicas : un Pod par nœud éligible. Partez d'un YAML de Deployment, changez le kind et retirez replicas et strategy.",

	"ds-02|ciblage":       "nodeSelector se déclare dans le spec du template. Le sélecteur et les labels du template doivent concorder.",
	"ds-02|configuration": "Le conteneur busybox doit exécuter une commande durable, sinon il redémarre en boucle.",
	"ds-02|disponibilité": "Le nombre de Pods disponibles doit égaler le nombre désiré. kubectl rollout status daemonset l'attend.",

	"ds-03|tolérance":               "tolerations se déclare dans le spec du template. key, operator, value et effect doivent correspondre exactement au taint.",
	"ds-03|configuration conservée": "Ajoutez la tolérance sans toucher au sélecteur, à l'image ni à la commande.",
	"ds-03|disponibilité":           "Attendez que tous les Pods désirés soient disponibles après le rollout.",

	"ds-04|stratégie":       "updateStrategy.type change la stratégie de mise à jour. Changez aussi l'image du template.",
	"ds-04|pods renouvelés": "Avec OnDelete, un Pod n'est remplacé que si on le supprime. Supprimez les anciens, attendez les nouveaux, puis écrivez leurs noms triés.",

	// StatefulSets
	"sts-01|service headless": "Un Service headless a clusterIP: None. Ce champ ne change pas sur un Service existant : recréez le Service.",
	"sts-01|statefulset":      "serviceName relie le StatefulSet au Service headless. Sélecteur, labels du template, image et port doivent concorder.",
	"sts-01|identités":        "Les Pods sont créés un par un, avec un ordinal : <nom>-0, <nom>-1... Attendez que chacun soit Ready.",

	"sts-02|service et ordre": "podManagementPolicy et serviceName se déclarent dans le spec du StatefulSet. Le Service associé est headless.",
	"sts-02|initialisation":   "L'init container et le conteneur principal montent le même volume emptyDir. Vérifiez noms, images, commande et chemins de montage.",
	"sts-02|identités":        "Avec OrderedReady, un Pod n'est créé que lorsque le précédent est Ready. Un init container en échec bloque la suite.",

	"sts-03|stockage":         "volumeClaimTemplates crée un PVC par Pod. Il porte nom, storageClassName, accessModes et taille. Le conteneur monte un volume du même nom.",
	"sts-03|service headless": "Créez le Service headless référencé par serviceName, avec le même sélecteur que le StatefulSet.",
	"sts-03|persistance":      "Écrivez le fichier dans le volume monté du premier Pod, supprimez ce Pod, puis vérifiez qu'il est encore là après recréation.",
	"sts-03|disponibilité":    "Un PVC Pending bloque le Pod. kubectl get pvc et describe pvc montrent la cause : StorageClass, taille...",

	"sts-04|stratégie":           "updateStrategy.rollingUpdate.partition ne met à jour que les ordinaux supérieurs ou égaux à la partition. Changez aussi l'image et le nombre de réplicas.",
	"sts-04|partition appliquée": "Les Pods sous la partition gardent l'ancienne image. Comparez l'image de chaque Pod avec kubectl get pods -o custom-columns.",
	"sts-04|disponibilité":       "Les réplicas ajoutés doivent être Ready. Attendez que tous les Pods tournent.",

	"sts-05|statefulset supprimé": "kubectl delete statefulset --cascade=orphan supprime le contrôleur et laisse ses Pods en place.",
	"sts-05|service conservé":     "Le Service headless doit rester, avec clusterIP: None et le bon sélecteur. Ne le supprimez pas.",
	"sts-05|pods orphelins":       "Corrigez et recréez d'abord le StatefulSet, enregistrez les noms de ses Pods, puis supprimez-le en orphelin. Un Pod orphelin n'a plus d'ownerReferences.",

	// Volumes
	"vol-01|ressource":     "Le Pod porte le nom et le label demandés, dans le namespace de l'exercice.",
	"vol-01|volume":        "Le volume se déclare dans spec.volumes, le montage dans le conteneur sous volumeMounts. Les deux sont reliés par le nom du volume.",
	"vol-01|contenu":       "Écrivez le fichier dans le chemin de montage, depuis la commande du conteneur ou avec kubectl exec. Le contenu doit être exact.",
	"vol-01|disponibilité": "Le conteneur doit rester actif après l'écriture. Attendez la condition Ready.",

	"vol-02|ressource":      "Le Pod porte le nom et le label demandés.",
	"vol-02|volume mémoire": "medium et sizeLimit se déclarent sous emptyDir. Un emptyDir en mémoire est un tmpfs.",
	"vol-02|contenu":        "Écrivez le fichier dans le volume monté. Le contenu doit être exact, sans espace en plus.",
	"vol-02|disponibilité":  "Le conteneur doit rester actif. Attendez la condition Ready.",

	"vol-03|deployment":     "Le sélecteur et les labels du template doivent concorder. Le replica doit être disponible.",
	"vol-03|volume partagé": "Le volume emptyDir est déclaré dans le spec du template. Chaque conteneur le monte sur son propre chemin.",
	"vol-03|contenu":        "Le fichier écrit par loader doit être lisible par web à travers le volume partagé. loader doit écrire puis rester actif.",

	"vol-04|pvc":           "storageClassName, accessModes et resources.requests.storage se déclarent dans le spec du PVC. Avec local-path, le PVC peut attendre le premier Pod avant d'être Bound.",
	"vol-04|pod":           "Le volume du Pod référence le PVC avec persistentVolumeClaim.claimName. Le montage se fait dans le conteneur.",
	"vol-04|disponibilité": "Un PVC non lié laisse le Pod Pending. kubectl describe pod et describe pvc montrent la cause.",

	"vol-05|pvc":         "Vérifiez taille, mode d'accès et StorageClass du PVC. Il doit être Bound.",
	"vol-05|pod":         "Le Pod recréé doit reprendre le même PVC, avec le même nom de volume et le même chemin.",
	"vol-05|persistance": "Écrivez le fichier dans le volume, supprimez le Pod, recréez-le : le fichier doit être encore là, avec le contenu exact.",

	"vol-06|configmap conservé": "Ne modifiez pas le ConfigMap fourni : le Pod le consomme.",
	"vol-06|volume":             "Un volume configMap référence le ConfigMap par son nom. Chaque clé devient un fichier dans le répertoire de montage.",
	"vol-06|contenu":            "Le fichier porte le nom de la clé du ConfigMap. Vérifiez le chemin de montage.",
	"vol-06|disponibilité":      "Un ConfigMap absent bloque le Pod en ContainerCreating. Attendez la condition Ready.",

	"vol-07|pvc":     "kubectl describe pvc donne la raison du Pending. La StorageClass d'un PVC est immuable : supprimez le Pod, puis recréez le PVC.",
	"vol-07|pod":     "Recréez le Pod avec le même nom, branché sur le PVC corrigé.",
	"vol-07|contenu": "Écrivez le fichier attendu dans le volume, une fois le Pod Ready. Le contenu doit être exact.",

	"vol-08|pvc":        "Vérifiez taille, mode d'accès et StorageClass du PVC. Il doit être Bound.",
	"vol-08|deployment": "Le volume persistentVolumeClaim se déclare dans le spec du template, le montage dans le conteneur nginx.",
	"vol-08|contenu":    "Écrivez la page dans le volume, depuis le Pod en cours, avec kubectl exec. Le contenu doit être exact.",

	// Services
	"svc-01|deployment": "kubectl create deployment avec --replicas et --port. Contrôlez le nom du conteneur et le label app.",
	"svc-01|service":    "kubectl expose crée un Service qui reprend le sélecteur du Deployment. port est le port du Service, targetPort celui du conteneur.",
	"svc-01|endpoints":  "Un Service n'a d'Endpoints que si son sélecteur trouve des Pods Ready. Comparez sélecteur et labels des Pods.",

	"svc-02|service":             "Un Service NodePort se crée avec kubectl create service nodeport --node-port, ou en YAML. Le sélecteur doit viser les Pods du Deployment.",
	"svc-02|endpoints":           "Endpoints vides : le sélecteur ne correspond pas aux labels des Pods. kubectl get endpoints <service> le montre.",
	"svc-02|deployment conservé": "Le Deployment fourni ne doit pas changer.",

	"svc-03|sélecteur":           "Comparez le sélecteur du Service avec les labels des Pods : kubectl get pods --show-labels. Corrigez le Service, pas le Deployment.",
	"svc-03|endpoints":           "Les Endpoints apparaissent dès que le sélecteur trouve des Pods Ready.",
	"svc-03|deployment conservé": "Laissez le Deployment et ses labels tels quels.",

	"svc-04|ports nommés": "Un Service à plusieurs ports exige un name sur chaque port. Les deux ports peuvent cibler le même targetPort.",
	"svc-04|endpoints":    "Vérifiez que le sélecteur vise bien les Pods du Deployment.",

	"svc-05|targetPort nommé": "targetPort peut être le nom d'un containerPort. Le nom doit être celui déclaré dans le conteneur.",
	"svc-05|endpoints":        "Si le nom du targetPort ne correspond à aucun port nommé du conteneur, les Endpoints n'ont pas de port.",

	"svc-06|service":   "Un Service sans sélecteur ne crée pas d'Endpoints. Écrivez le YAML sans le champ selector.",
	"svc-06|endpoints": "La ressource Endpoints porte le même nom que le Service. subsets contient addresses et ports.",

	"svc-07|deployment": "Le conteneur busybox doit exécuter une commande durable. Sélecteur et labels du template concordent.",
	"svc-07|headless":   "clusterIP: None rend le Service headless. Ce champ ne change pas sur un Service existant : recréez-le.",
	"svc-07|endpoints":  "Un Service headless publie une adresse par Pod Ready sélectionné.",

	"svc-08|targetPort": "targetPort doit être le port où le conteneur écoute. Corrigez-le sans changer le port du Service.",
	"svc-08|endpoints":  "Les Endpoints reprennent le targetPort. Le mauvais port ne doit plus y apparaître.",

	"svc-09|loadbalancer":        "Un Service LoadBalancer se crée comme un ClusterIP, avec le type LoadBalancer. EXTERNAL-IP peut rester Pending sans contrôleur.",
	"svc-09|endpoints":           "Vérifiez que le sélecteur vise les Pods du Deployment.",
	"svc-09|deployment conservé": "Le Deployment fourni ne doit pas changer.",

	"svc-10|loadbalancer": "Le type d'un Service se change avec kubectl edit ou kubectl patch, sans recréer le Service. Sélecteur et ports restent.",
	"svc-10|endpoints":    "Changer le type ne touche pas au sélecteur : les Endpoints doivent rester présents.",

	"svc-11|stable":  "Le Deployment stable sélectionne app et track. Les labels du template portent les deux.",
	"svc-11|canary":  "Le canary a son propre track, sa propre image et un seul réplica. Il ne doit pas sélectionner les Pods stables.",
	"svc-11|service": "Le Service ne sélectionne que le label commun aux deux versions : il répartit le trafic sur tous les Pods.",

	"svc-12|bascule":           "Le sélecteur du Service se modifie avec kubectl patch ou kubectl edit. Ajoutez le label de version au sélecteur.",
	"svc-12|trafic vert":       "Les Endpoints ne doivent contenir que les Pods de la nouvelle version. kubectl get endpoints les liste.",
	"svc-12|les deux versions": "Une bascule blue/green garde les deux versions : ne supprimez ni ne modifiez les Deployments.",
}
