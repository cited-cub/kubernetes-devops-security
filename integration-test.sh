#!/bin/bash

#integration-test.sh

sleep 5s

PORT=$(kubectl -n default get svc devsecops-svc -o jsonpath='{.spec.ports[0].nodePort}')
applicationURL=$(kubectl get no -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
echo $PORT
echo $applicationURL:$PORT$applicationURI

if [ ! -z "$PORT" ];
then
    response=$(curl -s $applicationURL:$PORT$applicationURI)
    echo $response
    http_code=$(curl -s -o /dev/null -w "%{http_code}" $applicationURL:$PORT$applicationURI)
    echo $http_code

    if [[ "$response" -eq 100 ]];
        then
            echo "Increment Test Passed"
        else
            echo "Increment Test Failed"
            exit 1;
    fi;

    if [[ "$http_code" -eq 200 ]];
        then
            echo "HTTP Status Code Test Passed"
        else
            echo "HTTP Status Code is not 200"
            exit 1;
    fi;
else
    echo "The Service does not have a NodePort"
    exit 1;
fi;