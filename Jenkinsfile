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
    name: 'jnlp',
    image: 'jenkins/inbound-agent:latest'
    )
  ]) {
    node(POD_LABEL) {
        stage('Run shell') {
            sh 'echo hello world'
        }
    }
}
