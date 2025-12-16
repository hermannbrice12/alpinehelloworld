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
        NGROK_HTTP_URL = credentials('NGROK_HTTP_URL')
        NGROK_SSH_URL = credentials('NGROK_SSH_URL')
        SSH_CREDENTIALS = credentials('SSH_LOGIN')
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

       stage('Deploy to VM via Ngrok') {
    steps {
        script {

            // Extraire host et port depuis NGROK_SSH_URL (ex: 5.tcp.eu.ngrok.io:18001)
            def ngrok = env.NGROK_SSH_URL.split(':')
            def NGROK_HOST = ngrok[0]
            def NGROK_PORT = ngrok[1]

            withCredentials([
                usernamePassword(
                    credentialsId: 'SSH_LOGIN',
                    usernameVariable: 'SSH_USER',
                    passwordVariable: 'SSH_PASSWORD'
                )
            ]) {
                sh """
                    echo "🔧 Installation de sshpass si nécessaire..."
                    if ! command -v sshpass >/dev/null 2>&1; then
                        sudo apt update -y
                        sudo apt install -y sshpass
                    fi

                    echo "🚀 Déploiement sur la VM via Ngrok SSH..."
                    sshpass -p "$SSH_PASSWORD" ssh \
                      -o StrictHostKeyChecking=no \
                      -o UserKnownHostsFile=/dev/null \
                      -p ${NGROK_PORT} \
                      ${SSH_USER}@${NGROK_HOST} \
                      "docker pull ${ID_DOCKERHUB}/${IMAGE_NAME}:${IMAGE_TAG} && \
                       docker rm -f ${IMAGE_NAME} || true && \
                       docker run -d --name ${IMAGE_NAME} \
                       -p 80:5000 -e PORT=5000 \
                       ${ID_DOCKERHUB}/${IMAGE_NAME}:${IMAGE_TAG}"
                """
            }
        }
    }
}


    post {
    success {
        slackSend channel: '#jenkins-build',
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