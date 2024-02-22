#!/bin/bash

# Download the artifact form JFrog artifactory


CICD=true
WORKSPACE=/apps/opt/users
JOB_BASE_NAME=Test_demo

if[[$CICD == true]];then
    echo "CI/CD pipeline check"
    file="${WORKSPACE}/html/basic_report.html"
    REPORTNAME=${JOB_BASE_NAME}_${BUILD_NUMBER}.Test_demo_10
    echo "CICD check Starting"
    if[ -f "$file"];then
            echo "testReport file found sending to artifactory".
            curl -H X-JFrog-Art-Api-Token-T $file https://oneartifactorycloud/artifactory/CICD/Repoerts/$REPORTNAME.html
    else 
        
        echo "testReport not found"
    fi 
fi
