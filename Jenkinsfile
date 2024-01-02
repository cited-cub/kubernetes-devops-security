pipeline {
  agent {
    kubernetes {
      // cloud kubernetes
      yaml '''
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
            image: bitnami/kubectl
            securityContext:
              fsGroup: 1000
              runAsUser: 1000
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
          - name: trivy
            image: aquasec/trivy:0.17.2
            command:
            - sleep
            args:
            - 9999999
            volumeMounts:
            - name: trivy-data
              mountPath: /root/.cache
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
    }
    stage('Mutation Tests - PIT') {
      steps {
        container('maven') {
          sh "mvn org.pitest:pitest-maven:mutationCoverage"
        }
      }
    }
    stage('Vulnerability Scan - Docker') {
      parallel {
        stage('Dependency Scan') {
          steps {
            container('maven') {
              sh "mvn dependency-check:check"
            }
          }
        }
        stage('Trivy') {
          steps {
            container('trivy') {
              sh "sh trivy-docker-image-scan.sh"
            }
          }
        }
      }
    }
    stage('Build and push Java image') {
      steps {
        container('kaniko') {
          sh '''
            /kaniko/executor --context `pwd` --destination ${REGISTRY_URI}/numeric-app:""$GIT_COMMIT""
          '''
        }
      }
    }
    stage('Kubernetes deployment - DEV') {
      steps {
        container('kubectl') {
          sh '''
            sed -i "s#replace#${REGISTRY_URI}/numeric-app:${GIT_COMMIT}#g" k8s_deployment_service.yaml
          '''
          sh "kubectl version"
          sh "kubectl apply -f k8s_deployment_service.yaml"
        }
      }
    }
  }
  post {
    always {
      junit 'target/surefire-reports/*.xml'
      jacoco execPattern: 'target/jacoco.exec'
      pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
      dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
    }
  }
}
