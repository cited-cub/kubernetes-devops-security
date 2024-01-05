#!/bin/bash

#k8s-deployment.sh

imageName="${REGISTRY_URI}/numeric-app:${GIT_COMMIT}"
sed -i "s#replace#${imageName}#g" k8s_deployment_service.yaml

# kubectl -n default get deployment ${deploymentName} > /dev/null
# if [[ $? -ne 0 ]]; then
#     echo "deployment ${deploymentName} doesn't exist"
#     kubectl -n default apply -f k8s_deployment_service.yaml
# else
#     echo "deployment ${deploymentName} exists"
#     echo "image name - ${imageName}"
#     kubectl -n default set image deploy ${deploymentName}=${imageName} --record=true
# fi

kubectl -n default apply -f k8s_deployment_service.yaml
PORT=$(kubectl -n default get svc devsecops-svc -o jsonpath='{.spec.ports[0].nodePort}')
applicationURL=$(kubectl get no -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
echo $PORT
echo $applicationURL:$PORT$applicationURI

cat <<EOF | kubectl apply -f -
apiVersion: v1
data:
  PORT: "${PORT}"
  applicationURL: "${applicationURL}"
kind: ConfigMap
metadata:
  name: app-config
  namespace: devops-tools
EOF