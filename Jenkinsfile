pipeline {
    agent any

    options {
        // Automatically purge old build logs to prevent disk bloat
        buildDiscarder(logRotator(numToKeepStr: '5'))
        disableConcurrentBuilds()
    }

    stages {
        stage('Fetch') {
            steps {
                // Wipe workspace clean to avoid permission conflicts
                cleanWs()
                checkout scm
            }
        }

        stage('Build and Run') {
            steps {
                echo "Building and running application for testing..."
                // Defensive cleanup: remove existing container before starting
                sh 'docker rm -f sentiment-app || true'
                
                // Build the image
                sh 'docker build -t sentiment-api:unstable .'
                
                // Map 5000 to 5000 for the CI test environment to match test suite config
                sh 'docker run -d -p 5000:5000 --name sentiment-app sentiment-api:unstable'
                
                // Wait for the app to initialize
                sleep 5
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
                    // Requires "dockerhub-credentials-id" in Jenkins Credentials
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
                sh 'kubectl apply -f k8s/pvc.yaml'
            }
        }
    }

    post {
        always {
            // Cleanup workspace and stop the container to free disk/port
            cleanWs()
            sh 'docker rm -f sentiment-app || true'
        }
    }
}
