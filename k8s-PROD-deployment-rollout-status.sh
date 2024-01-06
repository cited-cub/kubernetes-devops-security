#!/bin/bash

#k8s-PROD-deployment-rollout-status.sh

sleep 60s

if [[ $(kubectl -n prod rollout status deploy ${deploymentName} --timeout 5s) != *"successfully rolled out"* ]];
then
    echo "Deployment ${deploymentName} rollout has failed"
    kubectl -n prod rollout undo deploy ${deploymentName}
    exit 1;
else
    echo "Deployment ${deploymentName} rollout is success"
fi