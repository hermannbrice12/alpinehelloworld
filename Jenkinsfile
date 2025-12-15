/* import shared-library */
//@Library('shared-library') _


pipeline {
    agent any
    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-tchofo') // ID des credentials DockerHub dans Jenkins
        ID_DOCKERHUB = "tchofo"
        IMAGE_NAME = "alpinehelloworld"
        IMAGE_TAG = "latest"
        PORT_EXPOSED = 80
        VM_HOST        = "ubuntu1"            
        VM_USER        = "tchofo"
        VM_SSH_CRED    = "ssh-tchofo-vm"
        SLACK_CHANNEL = '#jenkins-builds' //  channel Slack
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'master', url: 'https://github.com/hermannbrice12/alpinehelloworld.git'
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    sh """
                        docker build -t ${ID_DOCKERHUB}/${IMAGE_NAME}:${IMAGE_TAG} .
                    """
                }
            }
        }
        stage('Run Container') {
            steps {
                script {
                    sh """
                        # Supprimer ancien conteneur s’il existe
                        docker rm -f ${IMAGE_NAME} || true
                        
                        # Lancer le conteneur dans le même réseau que Jenkins
                       docker run --name $IMAGE_NAME -d -p ${PORT_EXPOSED}:5000 -e PORT=5000 $ID_DOCKERHUB/$IMAGE_NAME:$IMAGE_TAG
                        
                        sleep 5
                    """
                }
            }
        }
        stage('Test from Jenkins') {
            steps {
                script {
                    sh """

                        curl http://localhost | grep -qi "Hello world!"
                    """
                }
            }
        }
        stage('Clean Container') {
            steps {
                script {
                    sh """
                        docker stop ${IMAGE_NAME} || true
                        docker rm ${IMAGE_NAME} || true
                    """
                }
            }
        }
        stage('Login to DockerHub') {
            steps {
                script {
                    sh """
                        echo "${DOCKERHUB_CREDENTIALS_PSW}" | docker login -u "${DOCKERHUB_CREDENTIALS_USR}" --password-stdin
                    """
                }
            }
        }
        stage('Push Docker Image') {
            steps {
                script {
                    sh """
                        docker push ${ID_DOCKERHUB}/${IMAGE_NAME}:${IMAGE_TAG}
                    """
                }
            }
        }
    }


            stage('Deploy to VM') {
                steps {
                    script {
                       withCredentials([
                           sshUserPrivateKey(
                               credentialsId: 'ssh-tchofo-vm',
                               keyFileVariable: 'SSH_KEY',
                               usernameVariable: 'SSH_USER'
                    )
                ]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no -i "${SSH_KEY}" ${SSH_USER}@${VM_HOST} \\
                          'docker pull ${ID_DOCKERHUB}/${IMAGE_NAME}:${IMAGE_TAG} && \\
                           docker rm -f ${IMAGE_NAME} || true && \\
                           docker run -d --name ${IMAGE_NAME} -p 80:5000 -e PORT=5000 ${ID_DOCKERHUB}/${IMAGE_NAME}:${IMAGE_TAG}'
                    """
                }
            }
        }
    }
} 


  /*
post {
    success {
        slackSend (
            channel: "${SLACK_CHANNEL}",
            color: "good",
            message: "✅ Build & Push réussi pour l’image *${ID_DOCKERHUB}/${IMAGE_NAME}:${IMAGE_TAG}*"
        )
    }
    failure {
        slackSend (
            channel: "${SLACK_CHANNEL}",
            color: "danger",
            message: "❌ Échec du pipeline pour l’image *${ID_DOCKERHUB}/${IMAGE_NAME}:${IMAGE_TAG}*"
        )
    }
}
*/

post {
        always {
            script {
                slackNotifier(currentBuild.result)
            }
        }
    }
}
