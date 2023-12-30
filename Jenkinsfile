podTemplate(containers: [
    containerTemplate(
        name: 'maven', 
        image: 'maven:3.8.1-jdk-8', 
        command: 'sleep', 
        args: '30d'
        )
  ]) {

    node(POD_LABEL) {
        stage('Get a Maven project') {
            git url: 'https://github.com/cited-cub/kubernetes-devops-security/', branch: 'main'
            sh 'ls -la'
            container('maven') {
                stage('Build a Maven project') {
                    sh '''
                    echo "maven build"
                    '''
                    sh "mvn clean package -DskipTests=true"
                }
            }
        }
    }
}