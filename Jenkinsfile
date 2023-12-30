pipeline {
  agent {
    kubernetes {
      // cloud kubernetes
      // label 'mypod'
      // containerTemplate {
      //   name 'maven'
      //   image 'maven:3.8.1-jdk-8'
      //   command 'sleep'
      //   args '30d'
      // }

      yaml '''
        apiVersion: v1
        kind: Pod
        metadata:
          labels:
            jenkins/label: mypod
        spec:
          containers:
          - name: maven
            image: maven:3.8.1-jdk-8
            command:
            - sleep
            args:
            - 30d
          - name: kaniko
            image: gcr.io/kaniko-project/executor:debug
            command:
            - sleep
            args:
            - 9999999
            volumeMounts:
            - name: kaniko-secret
              mountPath: /kaniko/.docker
          restartPolicy: Never
          volumes:
          - name: kaniko-secret
            secret:
              secretName: dockercred
              items:
              - key: .dockerconfigjson
                path: config.json
      '''     
    }

  }
  stages {
    stage('Get a Maven project') {
      steps {
        git url: 'https://github.com/cited-cub/kubernetes-devops-security/', branch: 'main'
        sh 'ls -la'
      }
    }
    stage('Build a Maven project') {
      steps {
        container('maven') {
          sh '''
            echo "maven build"
          '''
          sh "mvn clean package -DskipTests=true"
          archiveArtifacts artifacts: 'target/*.jar', followSymlinks: false
        }
      }
    }
    stage('Unit Tests - JUnit and Jacoco') {
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
    stage('Build Java Image') {
      steps {
        container('kaniko') {
          sh '''
            /kaniko/executor --context `pwd` --destination 039723078141.dkr.ecr.eu-central-1.amazonaws.com/numeric-app:""$GIT_COMMIT""
          '''
        }
      }
    }
  }
}
