//Permet d’utiliser des fonctions ou scripts partagés définis dans une bibliothèque Jenkins.
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
        SLACK_CHANNEL = '#jenkins-builds'
    //crédentials pour se connecter a aws
        EC2_HOST = "35.181.43.175"
        EC2_USER = "ubuntu"
    }

//Récupère le code source depuis le dépôt GitHub sur la branche master.
    stages {

        stage('Checkout') {
            steps {
                git branch: 'master',
                    url: 'https://github.com/hermannbrice12/alpinehelloworld.git'
            }
        }

//Construit l’image Docker localement à partir du Dockerfile du projet.
        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${ID_DOCKERHUB}/${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

 //Supprime tout conteneur existant du même nom et Lance un nouveau conteneur en arrière-plan, puis laisse le conteneur démarrer.   
        stage('Run Container') {
            steps {
                sh """
                    docker rm -f ${IMAGE_NAME} || true
                    docker run -d --name ${IMAGE_NAME} \
                      -p ${PORT_EXPOSED}:5000 \
                      -e PORT=5000 \
                      ${ID_DOCKERHUB}/${IMAGE_NAME}:${IMAGE_TAG}
                    sleep 10
                """
            }
        }

//Teste que l’application fonctionne en effectuant une requête HTTP et en cherchant la chaîne "Hello world!".
        stage('Test from Jenkins') {
            steps {
                sh "curl http://localhost | grep -qi 'Hello world!'"
            }
        }

//Arrête et supprime le conteneur Docker local.
        stage('Clean Container') {
            steps {
                sh """
                    docker stop ${IMAGE_NAME} || true
                    docker rm ${IMAGE_NAME} || true
                """
            }
        }

//Connexion à Docker Hub pour pouvoir pousser l’image.
        stage('Login to DockerHub') {
            steps {
                sh """
                    echo "${DOCKERHUB_CREDENTIALS_PSW}" | \
                    docker login -u "${DOCKERHUB_CREDENTIALS_USR}" --password-stdin
                """
            }
        }

//Envoie l’image Docker construite sur Docker Hub.
        stage('Push Docker Image') {
            steps {
                sh "docker push ${ID_DOCKERHUB}/${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

  //Déploie l’image Docker sur une VM en local via Ngrok.      
//         stage('Deploy to VM via Ngrok') {
//     steps {
//         script {

//             withCredentials([
//                 string(credentialsId: 'NGROK_SSH_URL', variable: 'NGROK_SSH_URL'),
//                 usernamePassword(
//                     credentialsId: 'SSH_LOGIN',
//                     usernameVariable: 'SSH_USER',
//                     passwordVariable: 'SSH_PASSWORD'
//                 )
//             ]) {
//                 def clean = env.NGROK_SSH_URL.replace('tcp://','')
//                 def ngrok  = clean.split(':')
//                 def NGROK_HOST = ngrok[0]
//                 def NGROK_PORT = ngrok[1]

//                 sh """
//                     echo "🚀 Déploiement via Ngrok SSH"

//                     sshpass -p "$SSH_PASSWORD" ssh \
//                       -o StrictHostKeyChecking=no \
//                       -o UserKnownHostsFile=/dev/null \
//                       -p ${NGROK_PORT} \
//                       ${SSH_USER}@${NGROK_HOST} \
//                       "docker pull ${ID_DOCKERHUB}/${IMAGE_NAME}:${IMAGE_TAG} && \
//                        docker rm -f ${IMAGE_NAME} || true && \
//                        docker run -d --name ${IMAGE_NAME} \
//                          -p 80:5000 -e PORT=5000 \
//                          ${ID_DOCKERHUB}/${IMAGE_NAME}:${IMAGE_TAG}"
//                 """
//             }
//         }
//     }
// }

// }


//Déploie l’image Docker sur EC2 AWS
stage('Deploy to AWS EC2 via SSH') {
            steps {
                sshagent(credentials: ['EC2_SSH_KEY']) {
                    sh """
                        echo "🚀 Déploiement sur EC2 AWS"

                        ssh -o StrictHostKeyChecking=no \
                            ${EC2_USER}@${EC2_HOST} '
                            docker pull ${ID_DOCKERHUB}/${IMAGE_NAME}:${IMAGE_TAG} &&
                            docker rm -f ${IMAGE_NAME} || true &&
                            docker run -d --name ${IMAGE_NAME} \
                              -p 80:5000 -e PORT=5000 \
                              ${ID_DOCKERHUB}/${IMAGE_NAME}:${IMAGE_TAG}
                        '
                    """
                }
            }
        }
    }



//Envoie une notification Slack selon que le pipeline réussisse ou échoue.
//     post {
//         success {
//             slackSend channel: '#jenkins-build',
//                       color: 'good',
//                       message: "✅ Build OK - ${env.JOB_NAME}"
//         }
//         failure {
//             slackSend channel: '#jenkins-builds',
//                       color: 'danger',
//                       message: "❌ Build FAIL - ${env.JOB_NAME}"
//         }
//     }
// }
