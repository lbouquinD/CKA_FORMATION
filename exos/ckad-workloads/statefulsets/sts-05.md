# sts-05 — Réparer puis supprimer proprement

Niveau 3 — 25 minutes

Contexte : namespace `ckad-sts-05`.

Préparez le scénario avec `./lab.sh start sts-05`.

Le StatefulSet `sessions` référence une ancienne identité réseau. Corrigez-le
pour utiliser le Service headless `sessions-headless`, le label `app=sessions`,
2 réplicas et l'image `nginx:1.27.3`.
Plusieurs champs d'un StatefulSet sont immuables : recréez la ressource avec le
même nom lorsque Kubernetes refuse leur modification.

Ensuite :

1. enregistrez les noms des Pods triés dans `/tmp/ckad-sts-05.txt`;
2. supprimez le StatefulSet en cascade orpheline afin que ses Pods restent
   présents;
3. ne supprimez ni le Service ni les Pods.

Le validateur contrôle l'état final après suppression du StatefulSet.
