def label = "cars-api-${UUID.randomUUID().toString()}"

podTemplate(label: label, containers: [
  containerTemplate(name: 'maven', image: 'maven:3.3.9-jdk-8-alpine', ttyEnabled: true, command: 'cat'),
  containerTemplate(alwaysPullImage: false, args: 'cat', command: '/bin/sh -c', image: 'lachlanevenson/k8s-helm:v2.11.0', name: 'helm-container', ttyEnabled: true),
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
  
  def CHARTMUSEUM_URL =  'http://helm-chartmuseum:8080'
  
  def HELM_CHART_NAME = 'devops/cars-api'
  
  def KUBE_NAMESPACE
  
  def IMAGE_POSTFIX =''
  
  def HELM_DEPLOY_NAME
  
  def PROJECT_NAME = 'cars-api'
  
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
                    
                    HELM_DEPLOY_NAME = KUBE_NAMESPACE + PROJECT_NAME
                    
                    IMAGE = readMavenPom().getArtifactId()
                    VERSION = readMavenPom().getVersion()
                }
                
                stage('Contruindo o projeto com Maven') {
                    sh 'mvn clean install -Dmaven.test.skip=true'
                    sh "cp target/${IMAGE}-${VERSION}.jar $MAVEN_REPO_DIR/${IMAGE}-${VERSION}.jar"
                }
            }
        }
        
        stage("Package"){
                container("docker-container"){
                    echo 'Iniciando empacotamento com docker' 
                    
                    
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-leandropantoja', passwordVariable: 'DOCKER_HUB_PASSWORD', usernameVariable: 'DOCKER_HUB_USER')]) {
                        sh "docker login -u ${DOCKER_HUB_USER} -p ${DOCKER_HUB_PASSWORD}"
                        sh "cp ${MAVEN_REPO_DIR}/${IMAGE}-${VERSION}.jar ${IMAGE}-${VERSION}.jar"
                        sh "sed -i 's/APP_NAME/${IMAGE}-${VERSION}.jar/g' Dockerfile "
                        DOCKER_HUB_USERNAME = DOCKER_HUB_USER
                    }

                    IMAGE_FINAL_NAME = DOCKER_HUB_USERNAME.trim()+'/'+IMAGE+':'+VERSION
                    echo IMAGE_FINAL_NAME
                    sh "docker build -t ${IMAGE_FINAL_NAME} ."
                    sh "docker push ${IMAGE_FINAL_NAME}"
                }
        }

        
        
        stage("Deploy"){
                container("helm-container"){
                    echo 'Iniciando deploy com helm' 
                    sh """
                        helm init --client-only
                        helm repo add devops ${CHARTMUSEUM_URL}
                        helm repo update
                    """
                     try {
                        //Upgrade
                        sh "helm upgrade  --namespace=${KUBE_NAMESPACE} ${HELM_DEPLOY_NAME} ${HELM_CHART_NAME} --set image.tag=${VERSION}"
                    }

                    catch(Exception e){
                        //Install
                        sh "helm install  --namespace=${KUBE_NAMESPACE} --name=${HELM_DEPLOY_NAME} ${HELM_CHART_NAME} --set image.tag=${VERSION}"
                    }
    

                }
        }

        
        
    }
  
}
