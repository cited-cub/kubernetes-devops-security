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
    HARBOR_URL = '18.213.245.123:30500'
    HARBOR_PROJECT = 'devsecops'
    IMAGE_NAME = 'devsecops-app'
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
  }
}