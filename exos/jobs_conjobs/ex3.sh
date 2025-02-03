#!/bin/bash  

RED="\e[31m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"



yaml=$(cat << EOF
apiVersion: batch/v1
kind: CronJob
metadata:
  name: ex3cron
  namespace: default
spec:
  schedule: "0 * * * *" 
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: task-exec
              image: alpine
              command: ["/bin/sh", "-c", "echo Bonjour depuis le cronjob ex3cron"]
          restartPolicy: OnFailure
EOF
)

# Apply the YAML using kubectl
kubectl apply -f - << EOF
$yaml
EOF