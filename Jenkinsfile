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
    image: 'jenkins/inbound-agent:4.13.3-1'
    )
  ]) {
    node(POD_LABEL) {
      container('jnlp') {
        stage('Run shell') {
            sh 'echo hello world'
        }
      }
    }
}
