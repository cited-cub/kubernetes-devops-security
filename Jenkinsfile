podTemplate(containers: [
  containerTemplate(
    name: 'maven',
    image: 'maven:3.6.3-jdk-8',
    command: 'sleep',
    args: '30d'
    )
  ]) {
    node(POD_LABEL) {
      stage('Get a Maven project') {
        sh "pwd"
        git branch: 'main', url: 'https://github.com/cited-cub/kubernetes-devops-security/'
        sh "ls -la"
        container('maven') {
          stage('Build Artifact') {
            steps {
              sh "pwd"
              sh "ls -la"
              sh "mvn clean package -DskipTests=true"
              archive 'target/*.jar' //so that they can be downloaded later
            }
          }
        }
      }
    }
}