pipeline {
  agent {
    kubernetes {
      // cloud kubernetes
      label 'mypod'
      containerTemplate {
        name 'maven'
        image 'maven:3.8.1-jdk-8'
        command 'sleep'
        args '30d'
      }
    }
  }
  stages {
    stage('Get a Maven project') {
      git url: 'https://github.com/cited-cub/kubernetes-devops-security/', branch: 'main'
      sh 'ls -la'
      container('maven') {
        stage('Build a Maven project') {
          sh '''
            echo "maven build"
          '''
          sh "mvn clean package -DskipTests=true"
          archiveArtifacts artifacts: 'target/*.jar', followSymlinks: false
        }
        stage('Unit Tests - JUnit and Jacoco') {
          sh "mvn test"
        }
      }
    }
  }
}

// podTemplate(containers: [
//   containerTemplate(
//       name: 'maven', 
//       image: 'maven:3.8.1-jdk-8', 
//       command: 'sleep', 
//       args: '30d'
//       )
//   ]) {

//   node(POD_LABEL) {
//     stage('Get a Maven project') {
//       git url: 'https://github.com/cited-cub/kubernetes-devops-security/', branch: 'main'
//       sh 'ls -la'
//       container('maven') {
//         stage('Build a Maven project') {
//           sh '''
//             echo "maven build"
//           '''
//           sh "mvn clean package -DskipTests=true"
//           archiveArtifacts artifacts: 'target/*.jar', followSymlinks: false
//         }
//         stage('Unit Tests - JUnit and Jacoco') {
//           sh "mvn test"
//         }
//       }
//     }
//     post {
//       always {
//         junit 'target/surefire-reports/*.xml'
//         jacoco execPattern: 'target/jacoco.exec'
//       }
//     }
//   }
// }