pipeline {
    agent any

    options {
        // Automatically delete old build artifacts to save disk space
        buildDiscarder(logRotator(numToKeepStr: '5'))
        disableConcurrentBuilds()
    }

    stages {
        stage('Fetch') {
            steps {
                cleanWs() // Ensure workspace is empty before starting
                checkout scm
            }
        }

        stage('Build and Run') {
            steps {
                echo "Building application image..."
                // Build the image using the optimized Dockerfile
                sh 'docker build -t sentiment-api:unstable .'
                // Run the container
                sh 'docker run -d -p 32500:5000 --name sentiment-app sentiment-api:unstable || true'
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
                    // Uses the registry credentials stored in Jenkins
                    docker.withRegistry('', 'dockerhub-credentials-id') {
                        sh 'docker tag sentiment-api:unstable abdullahghaffarr/sentiment-api:latest'
                        sh 'docker push abdullahghaffarr/sentiment-api:latest'
                    }
                }
            }
        }

        stage('Deploy to Minikube') {
            steps {
                echo "Deploying to Kubernetes cluster..."
                sh 'kubectl apply -f k8s/blue-deployment.yaml'
                sh 'kubectl apply -f k8s/green-deployment.yaml'
                sh 'kubectl apply -f k8s/service.yaml'
                sh 'kubectl apply -f k8s/pvc.yaml'
            }
        }
    }

    post {
        always {
            // Cleanup workspace after build to free disk space
            cleanWs()
            // Optional: Remove container to prevent port conflicts
            sh 'docker rm -f sentiment-app || true'
        }
    }
}
