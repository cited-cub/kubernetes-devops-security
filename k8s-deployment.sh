#!/bin/bash

#k8s-deployment.sh

imageName="${REGISTRY_URI}/numeric-app:${GIT_COMMIT}"
sed -i "s#replace#${imageName}#g" k8s_deployment_service.yaml
kubectl -n default get deployment ${deploymentName} > /dev/null

# if [[ $? -ne 0 ]]; then
#     echo "deployment ${deploymentName} doesn't exist"
#     kubectl -n default apply -f k8s_deployment_service.yaml
# else
#     echo "deployment ${deploymentName} exists"
#     echo "image name - ${imageName}"
#     kubectl -n default set image deploy ${deploymentName}=${imageName} --record=true
# fi

kubectl -n default apply -f k8s_deployment_service.yaml