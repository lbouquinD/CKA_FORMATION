
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-ex2
  namespace: right-ns
spec:
  replicas: 1 # Nombre de pods
  selector:
    matchLabels:
      app: mon-app
  template:
    metadata:
      labels:
        app: mon-app
    spec:
      serviceAccountName: ex2sa
      containers:
        - name: mon-conteneur
          image: laurentsogeti/ckad_formation_permission:0.0.10
EOF



# # 6. Vérification des autorisations
# echo "Vérification des autorisations du compte de service ex2sa :"

# # Lister les pods (devrait être autorisé)
# kubectl auth can-i list pods --as=system:serviceaccount:right-ns:ex2sa -n right-ns
# # Obtenir les logs du pod de test (devrait être autorisé)
# kubectl auth can-i get pods/log --as=system:serviceaccount:right-ns:ex2sa -n right-ns
# # Créer des pods (devrait être interdit)
# kubectl auth can-i create pods --as=system:serviceaccount:right-ns:ex2sa -n right-ns
# # Supprimer des pods (devrait être interdit)
# kubectl auth can-i delete pods --as=system:serviceaccount:right-ns:ex2sa -n right-ns