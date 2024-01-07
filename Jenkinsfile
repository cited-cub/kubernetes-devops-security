@Library('slack') _

//////// ****************************** Code for fetching Failed Stage Name ****************************** ////////
import io.jenkins.blueocean.rest.impl.pipeline.PipelineNodeGraphVisitor
import io.jenkins.blueocean.rest.impl.pipeline.FlowNodeWrapper
import org.jenkinsci.plugins.workflow.support.steps.build.RunWrapper
import org.jenkinsci.plugins.workflow.actions.ErrorAction

// Get information about all stages, including the failure cases
//Returns a list of maps: [[id, failedStageName, result, errors]]
@NonCPS
List<Map> getStageResults( RunWrapper build ) {

  // Get all pipeline nodes that represent stages
  def visitor = new PipelineNodeGraphVisitor( build.rawBuild )
  def stages = visitor.pipelineNodes.findAll{ it.type == FlowNodeWrapper.NodeType.STAGE }

  return stages.collect{ stage ->
  
    // Get all the errors from the stage
    def errorActions = stage.getPipelineActions( ErrorAction )
    def errors = errorActions?.collect{ it.error }.unique()
    
    return [
        id: stage.id,
        failedStageName: stage.displayName,
        result: "${stage.status.result}",
        errors: errors
    ]
  }
}

// Get information of all failed stages
@NonCPS
List<Map> getFailedStages( RunWrapper build ) {
  return getStageResults( build ).findAll{ it.result == 'FAILURE' }
}

pipeline {
  environment {
    deploymentName = "devsecops"
    containerName = "devsecops-container"
    serviceName = "devsecops-svc"
    imageName = "${REGISTRY_URI}/numeric-app:${BUILD_TAG}"
    applicationURL="http://www.google.com"
    applicationURI="/increment/99"
  }

  agent {
    kubernetes {
      // cloud kubernetes
      yaml """
        apiVersion: v1
        kind: Pod
        metadata:
          labels:
            jenkins/label: mypod
        spec:
          serviceAccountName: jenkins-admin
          containers:
          - name: maven
            image: maven:3.8.1-jdk-8
            command:
            - sleep
            args:
            - 30d
            volumeMounts:
            - name: maven-data
              mountPath: /root/.m2/repository
          - name: kaniko
            image: gcr.io/kaniko-project/executor:debug
            env:
            - name: REGISTRY_URI
              valueFrom:
                configMapKeyRef:
                  name: kaniko-config
                  key: registryUri
            command:
            - sleep
            args:
            - 9999999
            volumeMounts:
            - name: kaniko-secret
              mountPath: /kaniko/.docker
          - name: kubectl
            image: ${REGISTRY_URI}/kubectl-curl
            securityContext:
              fsGroup: 1000
              runAsUser: 1000
            command:
            - sleep
            args:
            - 9999999
          - name: trivy1
            image: aquasec/trivy:0.17.2
            command:
            - sleep
            args:
            - 9999999
            volumeMounts:
            - name: trivy-data
              mountPath: /root/.cache
          - name: trivy2
            image: aquasec/trivy:0.17.2
            command:
            - sleep
            args:
            - 9999999
            volumeMounts:
            - name: trivy-data
              mountPath: /root/.cache
            env:
            - name: TRIVY_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: dockerpwd
                  key: ECR_PASSWORD
            - name: TRIVY_USERNAME
              value: AWS
          - name: opa-conftest
            image: openpolicyagent/conftest:latest
            command:
            - sleep
            args:
            - 9999999
          - name: curl-jq
            image: gempesaw/curl-jq
            command:
            - sleep
            args:
            - 9999999
          - name: owasp-zap2docker
            image: owasp/zap2docker-weekly
            command:
            - sleep
            args:
            - 9999999
            volumeMounts:
            - mountPath: /config
              name: app-config-vol

          restartPolicy: Never
          volumes:
          - name: kaniko-secret
            secret:
              secretName: dockercred
              items:
              - key: .dockerconfigjson
                path: config.json
          - name: trivy-data
            persistentVolumeClaim:
              claimName: trivy-pv-claim
          - name: maven-data
            persistentVolumeClaim:
              claimName: maven-pv-claim
          - name: app-config-vol
            configMap:
              name: app-config
      """
    }
  }

  stages {
    stage('View environment variables') {
      steps {
        sh "env"
      }
    }
    // stage('Build a Maven project') {
    //   steps {
    //     container('maven') {
    //       sh '''
    //         echo "maven build"
    //       '''
    //       sh "mvn clean package -DskipTests=true"
    //       archiveArtifacts artifacts: 'target/*.jar', followSymlinks: false
    //     }
    //   }
    // }
    // stage('Unit Tests - JUnit and Jacoco') {
    //   steps {
    //     container('maven') {
    //       sh "mvn test"
    //     }
    //   }
    // }
    // stage('Mutation Tests - PIT') {
    //   steps {
    //     container('maven') {
    //       sh "mvn org.pitest:pitest-maven:mutationCoverage"
    //     }
    //   }
    // }
    // // stage('SonarQube Analysis') {
    // //   steps {
    // //     container('maven') {
    // //       sh "mvn sonar:sonar -Dsonar.projectKey=numeric-application -Dsonar.host.url=http://18.193.71.85:31186 -Dsonar.login=ce0105ec84117839b0c4bebe58c9cfb6148db1fe"
    // //     }
    // //   }
    // // }
    // stage('Vulnerability Scan - Docker') {
    //   parallel {
    //     stage('Dependency Scan') {
    //       steps {
    //         container('maven') {
    //           sh "mvn dependency-check:check"
    //         }
    //       }
    //     }
    //     stage('Trivy') {
    //       steps {
    //         container('trivy1') {
    //           sh "sh trivy-docker-image-scan.sh"
    //         }
    //       }
    //     }
    //     stage('OPA Conftest') {
    //       steps {
    //         container('opa-conftest') {
    //           sh 'conftest test --policy dockerfile-security.rego Dockerfile'
    //         }
    //       }
    //     }
    //   }
    // }
    // stage('Build and push Java image') {
    //   steps {
    //     container('kaniko') {
    //       sh '''
    //         /kaniko/executor --context `pwd` --destination ${REGISTRY_URI}/numeric-app:""$BUILD_TAG""
    //       '''
    //     }
    //   }
    // }
    // stage('Vulnerability Scan - Kubernetes') {
    //   parallel {
    //     stage('OPA Scan') {
    //       steps {
    //         container('opa-conftest') {
    //           sh 'conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml'
    //         }
    //       }
    //     }
    //     stage('Kubesec Scan') {
    //       steps {
    //         container('curl-jq') {
    //           sh "sh kubesec-scan.sh"
    //         }
    //       }
    //     }
    //     stage('Trivy Scan') {
    //       when {
    //         expression { false }
    //       }
    //       steps {
    //         container('trivy2') {
    //           sh "sh trivy-k8s-scan.sh"
    //         }
    //       }
    //     }
    //   } 
    // }
    // // stage('Kubernetes deployment - DEV') {
    // //   steps {
    // //     container('kubectl') {
    // //       sh '''
    // //         sed -i "s#replace#${REGISTRY_URI}/numeric-app:${BUILD_TAG}#g" k8s_deployment_service.yaml
    // //       '''
    // //       sh "kubectl version"
    // //       sh "kubectl apply -f k8s_deployment_service.yaml"
    // //     }
    // //   }
    // // }
    // stage('Kubernetes deployment - DEV') {
    //   parallel {
    //     stage("Deployment") {
    //       steps {
    //         container('kubectl') {
    //           sh "bash k8s-deployment.sh"
    //         }
    //       }
    //     }
    //     stage("Rollout Status") {
    //       steps {
    //         container('kubectl') {
    //           sh "bash k8s-deployment-rollout-status.sh"
    //         }
    //       }
    //     }
    //   }
    // }
    // stage('Integration Tests - DEV') {
    //   steps {
    //     container('kubectl') {
    //       script {
    //         try {
    //           sh "bash integration-test.sh"
    //         } catch (e) {
    //           sh "kubectl -n default rollout undo deploy ${deploymentName}"
    //           throw e
    //         }
    //       }
    //     }
    //   }
    // }
    // stage('OWASP ZAP - DAST') {
    //   steps {
    //     container('owasp-zap2docker') {
    //       sh "bash zap.sh"
    //     }
    //   }
    // }
    stage('Testing Slack') {
      steps {
        sh 'exit 0'
      }
    }
    stage('Promote to PROD?') {
      when {
        expression { false }
      }
      steps {
        timeout(time: 2, unit: 'DAYS') {
          input 'Do you want to approve the deployment to production environment/namespace?'
        }
      }
    }
    // // stage('K8S CIS Benchmark') {
    // //   steps {
    // //     script {
    // //       parallel {
    // //         "Master": {
    // //           sh "bash cis-master.sh"
    // //         }
    // //         "Etcd": {
    // //           sh "bash cis-etcd.sh"
    // //         }
    // //         "Kubelet": {
    // //           sh "bash cis-kubelet.sh"
    // //         }
    // //       }
    // //     }
    // //   }
    // // }
    // stage('K8S Deployment - PROD') {
    //   parallel {
    //     stage('Deployment') {
    //       steps {
    //         container('kubectl') {
    //           sh "sed -i 's#replace#${imageName}#g' k8s_PROD-deployment_service.yaml"
    //           sh "kubectl -n prod apply -f k8s_PROD-deployment_service.yaml"
    //           sh "kubectl -n prod apply -f istio-gateway-vs.yaml"
    //         }
    //       }
    //     }
    //     stage('Rollout Status') {
    //       steps {
    //         container('kubectl') {
    //           sh "bash k8s-PROD-deployment-rollout-status.sh"
    //         }
    //       }
    //     }
    //   }
    // }
    // stage('Integration Tests - PROD') {
    //   steps {
    //     container('kubectl') {
    //       script {
    //         try {
    //           sh "bash integration-test-PROD.sh"
    //         } catch (e) {
    //           sh "kubectl -n prod rollout undo deploy ${deploymentName}"
    //           throw e
    //         }
    //       }
    //     }
    //   }
    // }
  }
  post {
    // always {
    //   // junit 'target/surefire-reports/*.xml'
    //   // jacoco execPattern: 'target/jacoco.exec'
    //   // pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
    //   // dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
    //   // publishHTML([allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'owasp-zap-report', reportFiles: 'zap_report.html', reportName: 'OWASP ZAP HTML Report', reportTitles: 'OWASP ZAP HTML Report', useWrapperFileDirectly: true])
    //   // sendNotification currentBuild.result
    // }

    success {
      script {
        env.failedStage = "none"
        env.emoji = ":white_check_mark: :tada: :thumbsup_all:"
        sendNotification currentBuild.result
      }
    }

    failure {
      script {
        // Fetch information about failed stage
        def failedStages = getFailedStages( currentBuild )
        env.failedStage = failedStages.failedStageName
        env.emoji = ":x: :red_circle: :sos:"
        sendNotification currentBuild.result
      }
    }
  }
}