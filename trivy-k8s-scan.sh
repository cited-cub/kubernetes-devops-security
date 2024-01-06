#!/bin/bash

# trivy-k8s-scan

imageName="${REGISTRY_URI}/numeric-app:${BUILD_TAG}"
echo $imageName

trivy image --exit-code 0 --severity LOW,MEDIUM,HIGH --light $imageName
trivy image --exit-code 1 --severity CRITICAL --light $imageName

# Trivy scan result processing
exit_code=$?
echo "Exit Code : $exit_code"

# Check scan results
if [[ ${exit_code} == 1 ]]; then
    echo "Image scanning failed. Vulnerabilities found"
    exit 1;
else
    echo "Image scanning passed. No CRITICAL vulnerabilities found"
fi;