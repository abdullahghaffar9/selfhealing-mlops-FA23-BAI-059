pipeline {
    agent any

    stages {
        stage('Fetch') {
            steps {
                cleanWs()
                checkout scm
            }
        }

        stage('Build and Run') {
            steps {
                echo "Building and running application..."
                sh 'docker build -t sentiment-api:unstable .'
                sh 'docker run -d -p 32500:5000 --name sentiment-app sentiment-api:unstable'
            }
        }

        stage('Unit Test') {
            steps {
                echo "Running API unit tests..."
                sh 'pytest tests/test_api.py'
            }
        }

        stage('UI Test') {
            steps {
                echo "Running Selenium UI tests..."
                sh 'pytest tests/test_ui.py'
            }
        }

        stage('Build and Push') {
            steps {
                script {
                    docker.withRegistry('', 'dockerhub-credentials-id') {
                        sh 'docker tag sentiment-api:unstable abdullahghaffarr/sentiment-api:latest'
                        sh 'docker push abdullahghaffarr/sentiment-api:latest'
                    }
                }
            }
        }

        stage('Deploy to Minikube') {
            steps {
                echo "Deploying to Kubernetes..."
                sh 'kubectl apply -f k8s/blue-deployment.yaml'
                sh 'kubectl apply -f k8s/green-deployment.yaml'
                sh 'kubectl apply -f k8s/service.yaml'
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
