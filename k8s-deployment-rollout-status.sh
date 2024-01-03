#!/bin/bash

#k8s-deployment-rollout-status.sh

sleep 60s

if [[ $(kubectl -n default rollout status deploy ${deploymentName} --timeout 5s) != "deployment \"${deploymentName}\" successfully rolled out" ]];
then
    echo "Deployment ${deploymentName} Rollout has failed"
    kubectl -n default rollout undo deploy ${deploymentName}
    exit 1;
else
    echo "Deployment ${deploymentName} rollout is success"
fi