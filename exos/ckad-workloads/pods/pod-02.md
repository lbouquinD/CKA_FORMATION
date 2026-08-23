# pod-02 — Labels et annotations à chaud

Niveau 1

Contexte : namespace `ckad-pod-02`.

Préparez le scénario avec `./lab.sh start pod-02`.

Le Pod `web-dev` existe déjà. Modifiez-le **sans le redémarrer** :

- ajoutez l'annotation `builder=ansible`;
- remplacez le label `tier=frontend` par `tier=ui`;
- ajoutez le label `stage=test`.
