/* import shared-library */
//@Library('shared-library') _

pipeline {
    agent any
    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-tchofo')
        ID_DOCKERHUB = "tchofo"
        IMAGE_NAME = "alpinehelloworld"
        IMAGE_TAG = "latest"
        PORT_EXPOSED = 80
        VM_HOST      = "ubuntu1"
        VM_USER      = "tchofo"
        VM_SSH_CRED  = "ssh-tchofo-vm"
        SLACK_CHANNEL = '#jenkins-builds'
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
                        docker rm -f ${IMAGE_NAME} || true
                        docker run --name ${IMAGE_NAME} -d -p ${PORT_EXPOSED}:5000 -e PORT=5000 ${ID_DOCKERHUB}/${IMAGE_NAME}:${IMAGE_TAG}
                        sleep 10
                    """
                }
            }
        }

        stage('Test from Jenkins') {
            steps {
                script {
                    sh '''
                        curl http://localhost | grep -qi "Hello world!"
                    '''
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
                            ssh -o StrictHostKeyChecking=no -i ${SSH_KEY} ${SSH_USER}@${VM_HOST} \
                              'docker pull ${ID_DOCKERHUB}/${IMAGE_NAME}:${IMAGE_TAG} && \
                               docker rm -f ${IMAGE_NAME} || true && \
                               docker run -d --name ${IMAGE_NAME} -p 80:5000 -e PORT=5000 ${ID_DOCKERHUB}/${IMAGE_NAME}:${IMAGE_TAG}'
                        """
                    }
                }
            }
        }
    }

    post {
    success {
        slackSend channel: '#jenkins-builds',
                  color: 'good',
                  message: "✅ Build OK - ${env.JOB_NAME}"
    }
    failure {
        slackSend channel: '#jenkins-builds',
                  color: 'danger',
                  message: "❌ Build FAIL - ${env.JOB_NAME}"
    }
}

}