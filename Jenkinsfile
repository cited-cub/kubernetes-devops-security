pipeline {
  agent {
    kubernetes {
      yaml '''
        apiVersion: v1
        kind: Pod
        spec:
          containers:
          - name: maven
            image: maven:3.8.6-openjdk-8
            command:
            - sleep
            args:
            - infinity
          - name: kaniko
            image: gcr.io/kaniko-project/executor:debug
            command:
            - sleep
            args:
            - infinity
            volumeMounts:
            - name: harbor-creds
              mountPath: /kaniko/.docker
          - name: kubectl
            image: bitnami/kubectl:latest
            command:
            - sleep
            args:
            - infinity
          volumes:
          - name: harbor-creds
            secret:
              secretName: harbor-credentials
              items:
              - key: .dockerconfigjson
                path: config.json
      '''
    }
  }

  environment {
    HARBOR_URL = 'harbor.harbor.svc.cluster.local'
    HARBOR_PROJECT = 'devsecops'
    IMAGE_NAME = 'devsecops-app'
    GITEA_URL = 'gitea.gitea.svc.cluster.local:3000'
    GITEA_REPO = 'kubernetes-devops-security'
  }

  stages {
    stage('Build Artifact') {
      steps {
        container('maven') {
          sh "mvn clean package -DskipTests=true"
          archive 'target/*.jar'
        }
      }
    }

    stage('Unit Tests') {
      steps {
        container('maven') {
          sh "mvn test"
        }
      }
      post {
        always {
          junit 'target/surefire-reports/*.xml'
          jacoco execPattern: 'target/jacoco.exec'
        }
      }
    }

    stage('Docker Build and Push') {
      steps {
        container('kaniko') {
          sh "/kaniko/executor --context . --destination ${env.HARBOR_URL}/${env.HARBOR_PROJECT}/${env.IMAGE_NAME}:${env.GIT_COMMIT} --insecure"
        }
      }
    }

    stage('K8s Deployment - DEV') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'gitea-credentials', usernameVariable: 'GITEA_USER', passwordVariable: 'GITEA_TOKEN')]) {
          container('maven') {
            sh """
              sed -i "s|image: .*|image: ${env.HARBOR_URL}/${env.HARBOR_PROJECT}/${env.IMAGE_NAME}:${env.GIT_COMMIT}|g" k8s_deployment_service.yaml
              git config user.email 'jenkins@devsecops.local'
              git config user.name 'Jenkins CI'
              git add k8s_deployment_service.yaml argocd-application.yaml
              git commit -m 'Update devsecops-app image to ${env.GIT_COMMIT} [ci skip]'
              git push http://\${GITEA_USER}:\${GITEA_TOKEN}@${env.GITEA_URL}/\${GITEA_USER}/${env.GITEA_REPO}.git HEAD:main
            """
          }
          container('kubectl') {
            withKubeConfig([credentialsId: 'kubeconfig']) {
              sh """
                sed "s|GITEA_REPO_URL|http://${env.GITEA_URL}/\${GITEA_USER}/${env.GITEA_REPO}.git|g" argocd-application.yaml | kubectl apply -f -
              """
            }
          }
        }
      }
    }
  }
}