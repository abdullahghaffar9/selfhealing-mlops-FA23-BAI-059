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
                cleanWs()
                checkout scm
            }
        }

        stage('Build and Run') {
            steps {
                echo "Building and running application..."
                // Defensive cleanup
                sh 'docker rm -f sentiment-app || true'
                sh 'docker build -t sentiment-api:unstable .'
                
                // Start the app on port 5000
                sh 'docker run -d -p 5000:5000 --name sentiment-app sentiment-api:unstable'
                
                // ACTIVE READINESS CHECK (Fixed with seq for shell compatibility)
                echo "Waiting for ML Model to initialize..."
                sh '''#!/bin/bash
                    for i in $(seq 1 20); do
                        echo "Checking readiness (Attempt $i)..."
                        if curl -s -f http://localhost:5000/health > /dev/null; then
                            echo "Application is online and ready!"
                            exit 0
                        fi
                        sleep 5
                    done
                    echo "ERROR: Application failed to initialize within 100s. Logs:"
                    docker logs sentiment-app
                    exit 1
                '''
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
                    // Ensure you have "dockerhub-credentials-id" in Jenkins Credentials
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
            cleanWs()
            sh 'docker rm -f sentiment-app || true'
        }
    }
}
