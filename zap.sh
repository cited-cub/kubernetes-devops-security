#!/bin/bash

# first run this
# chmod 777 $(pwd)
echo $(id -u):$(id -g)
ln -s $(pwd) /zap/wrk
# zap-api-scan.py -t http://${applicationURL}:${PORT}/v3/api-docs -f openapi -r zap_report.html

# Comment above command and uncomment below command to run with CUSTOM RULES
zap-api-scan.py -t http://${applicationURL}:${PORT}/v3/api-docs -f openapi -c zap_rules -r zap_report.html

exit_code=$?

# HTML report
mkdir -p owasp-zap-report
mv zap_report.html owasp-zap-report

echo "Exit code: $exit_code"

if [[ ${exit_code} -ne 0 ]]; then
    echo "OWASP ZAP Report has either Low/Medium/High risk. Please check the HTML report"
    exit 1;
else
    echo "OWASP ZAP did not report any risk"
fi;
