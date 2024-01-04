#!/bin/bash

# PORT=$(kubectl -n default get svc ${serviceName} -o json | jq .spec.ports[].nodePort)

# # first run this
# chmod 777 $(pwd)
# echo $(id -u):$(id -g)
# zap-api-scan.py -t 
echo $PORT
echo $applicationURL:$PORT$applicationURI
