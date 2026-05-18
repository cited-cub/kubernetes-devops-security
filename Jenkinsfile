pipeline {
  agent {
    kubernetes {
      yaml '''
        apiVersion: v1
        kind: Pod
        spec:
          containers:
          - name: maven
            image: maven:3.9-eclipse-temurin-17
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
    GITEA_URL = 'gitea-http.gitea.svc.cluster.local:3000'
    GITEA_REPO = 'kubernetes-devops-security'
    GITEA_ARGOCD_APPS_REPO = 'argocd-apps'
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

    stage('SonarQube Analysis') {
      steps {
        container('maven') {
          withSonarQubeEnv('SonarQube') {
            sh "mvn sonar:sonar"
          }
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

              # Percent-encode @ in the token so it doesn't break the git URL
              GITEA_TOKEN_ENCODED=\$(printf '%s' "\${GITEA_TOKEN}" | sed 's/@/%40/g')

              # Push updated k8s manifest to the Gitea repo ArgoCD watches
              git clone http://\${GITEA_USER}:\${GITEA_TOKEN_ENCODED}@${env.GITEA_URL}/\${GITEA_USER}/${env.GITEA_REPO}.git /tmp/${env.GITEA_REPO}
              cp k8s_deployment_service.yaml /tmp/${env.GITEA_REPO}/
              cd /tmp/${env.GITEA_REPO}
              git config user.email 'jenkins@devsecops.local'
              git config user.name 'Jenkins CI'
              git add k8s_deployment_service.yaml
              git commit -m 'Update devsecops-app image to ${env.GIT_COMMIT} [ci skip]' || echo 'No changes to commit'
              git push
              cd -

              # Push argocd-application.yaml to the argocd-apps repo in Gitea
              git clone http://\${GITEA_USER}:\${GITEA_TOKEN_ENCODED}@${env.GITEA_URL}/\${GITEA_USER}/${env.GITEA_ARGOCD_APPS_REPO}.git /tmp/${env.GITEA_ARGOCD_APPS_REPO}
              sed "s|GITEA_REPO_URL|http://${env.GITEA_URL}/\${GITEA_USER}/${env.GITEA_REPO}.git|g" argocd-application.yaml > /tmp/${env.GITEA_ARGOCD_APPS_REPO}/devsecops-app.yaml
              cd /tmp/${env.GITEA_ARGOCD_APPS_REPO}
              git config user.email 'jenkins@devsecops.local'
              git config user.name 'Jenkins CI'
              git add devsecops-app.yaml
              git commit -m 'Add devsecops-app ArgoCD application [ci skip]' || echo 'No changes to commit'
              git push
              cd -
            """
          }
        }
      }
    }
  }
}