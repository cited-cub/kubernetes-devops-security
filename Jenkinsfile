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
          - name: docker
            image: docker:latest
            command:
            - sleep
            args:
            - infinity
            volumeMounts:
            - name: docker-sock
              mountPath: /var/run/docker.sock
          volumes:
          - name: docker-sock
            hostPath:
              path: /var/run/docker.sock
      '''
    }
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
        container('docker') {
          sh 'printenv'
          sh "docker build -t devsecops-app:${env.GIT_COMMIT} ."
        }
      }
    }
  }
}