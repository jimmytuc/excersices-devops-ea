pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'localhost:5000'
        BACKEND_IMAGE = "${DOCKER_REGISTRY}/hackathon-starter-backend"
        FRONTEND_IMAGE = "${DOCKER_REGISTRY}/hackathon-starter-frontend"
        KUBE_CONFIG = credentials('kube-config')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Install Dependencies') {
            steps {
                sh 'npm ci'
            }
        }
        
        stage('Run Tests') {
            steps {
                sh 'npm test'
            }
        }
        
        stage('Build and Push Backend Image') {
            steps {
                script {
                    docker.build("${BACKEND_IMAGE}:${BUILD_NUMBER}", "-f Dockerfile.backend .")
                    docker.image("${BACKEND_IMAGE}:${BUILD_NUMBER}").push()
                }
            }
        }
        
        stage('Build and Push Frontend Image') {
            steps {
                script {
                    docker.build("${FRONTEND_IMAGE}:${BUILD_NUMBER}", "-f Dockerfile.frontend .")
                    docker.image("${FRONTEND_IMAGE}:${BUILD_NUMBER}").push()
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    // Update image tags in Kubernetes manifests
                    sh """
                        sed -i 's|image: ${BACKEND_IMAGE}:.*|image: ${BACKEND_IMAGE}:${BUILD_NUMBER}|' backend-deployment.yaml
                        sed -i 's|image: ${FRONTEND_IMAGE}:.*|image: ${FRONTEND_IMAGE}:${BUILD_NUMBER}|' frontend-deployment.yaml
                    """
                    
                    // Apply Kubernetes manifests
                    withEnv(["KUBECONFIG=${KUBE_CONFIG}"]) {
                        sh 'kubectl apply -f backend-deployment.yaml'
                        sh 'kubectl apply -f frontend-deployment.yaml'
                        sh 'kubectl apply -f ingress.yaml'
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline succeeded! Application deployed successfully.'
        }
        failure {
            echo 'Pipeline failed. Please check the logs for details.'
        }
    }
}
