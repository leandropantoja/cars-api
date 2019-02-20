def label = "cars-api-${UUID.randomUUID().toString()}"

podTemplate(label: label, containers: [
  containerTemplate(name: 'maven', image: 'maven:3.3.9-jdk-8-alpine', ttyEnabled: true, command: 'cat'),
  containerTemplate(name: 'kubectl', image: 'lachlanevenson/k8s-kubectl:v1.8.0', command: 'cat', ttyEnabled: true),
  containerTemplate(alwaysPullImage: false, args: 'cat', command: '/bin/sh -c', envVars: [], image: 'docker', name: 'docker-container', ttyEnabled: true, workingDir: '/home/jenkins')
  ], volumes: [
  hostPathVolume(hostPath: '/var/run/docker.sock', mountPath: '/var/run/docker.sock'),
  persistentVolumeClaim(mountPath: '/root/.m2/repository', claimName: 'maven-repo', readOnly: false)
  ]) {

  def REPOS
  def IMAGE
  def VERSION
  def MAVEN_REPO_DIR = '/root/.m2/repository'
  def IMAGE_FINAL_NAME
  def DOCKER_HUB_USERNAME
  
  def KUBE_NAMESPACE
  
  def IMAGE_POSTFIX =''
  
    node(label) {
        stage('Checkout and Build') {
            container('maven') {
                stage('Git Checkout') {
                    echo 'Iniciando Clone do Respositório' 
                    REPOS = checkout scm                
                    GIT_BRANCH = REPOS.GIT_BRANCH
                    echo GIT_BRANCH
                    if(GIT_BRANCH.equals("master")){
                        echo 'Master' 
                        KUBE_NAMESPACE = 'default'
                        
                    } else if(GIT_BRANCH.equals("develop")){
                        echo 'develop' 
                        IMAGE_POSTFIX = '-RC'
                        KUBE_NAMESPACE = 'staging'
                    }
                    else {
                        def error =  "Não existe pipeline para a branch  ${GIT_BRANCH}"
                        echo error
                        throw new Exception(error)
                    }
                    
                    
                    IMAGE = readMavenPom().getArtifactId()
                    VERSION = readMavenPom().getVersion()
                }
                
                stage('Contruindo o projeto com Maven') {
                    sh 'mvn clean install -Dmaven.test.skip=true'
                    sh "cp target/${IMAGE}-${VERSION}.jar $MAVEN_REPO_DIR/${IMAGE}-${VERSION}.jar"
                }
            }
        }

        
        
        stage("Deploy"){
                container('kubectl') {
                    withKubeConfig([credentialsId: 'cad3c6a6-3b20-4afd-9c9f-9017a5c35824', serverUrl: 'https://192.168.55.34:6443']) {
                        echo 'Realizando deploy da API no Kubernetes'
                        sh "kubectl apply -f k8s/cars-api.yaml"
                        sh "kubectl apply -f istio/cars-api-auth.yaml"
                        sh "kubectl apply -f istio/mixer-rule-only-authorized.yaml"
                    }
                }
        }
        
        
    }
  
}
