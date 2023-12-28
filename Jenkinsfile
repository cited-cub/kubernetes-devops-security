//pipeline {
  //agent any

//  stages {
//    stage('Build Artifact') {
//      container('labcontainertemplate') {
//        steps {
//          sh "mvn clean package -DskipTests=true"
//          archive 'target/*.jar' //so that they can be downloaded later
//        }
//      }   
//    }
//  }
//}

podTemplate(containers: [
  containerTemplate(
    name: 'maven',
    image: 'maven:3.6.3-jdk-8'
    )
  ]) {
    node(POD_LABEL) {
      stage('Get a Maven project') {
        git 'https://github.com/cited-cub/kubernetes-devops-security.git'
        container('maven') {
          stage('Run shell') {
              sh 'echo hello world'
          }
        }
      }
    }
}
