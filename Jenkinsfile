pipeline {
    agent any
    
    environment {
        DOCKERHUB_CREDENTIALS_ID = 'dockerhub-credentials'
        DOCKERHUB_USER = 'abdullahghaffarr'
        IMAGE_NAME = 'sentiment-api'
    }
    
    stages {
        stage('Fetch') {
            steps {
                echo 'Executing Stage 1: Fetching source code from repository...'
                checkout scm
            }
        }
        
        stage('Build and Run') {
            steps {
                echo 'Executing Stage 2: Building unstable container image and running application layer...'
                sh 'docker build -t ${DOCKERHUB_USER}/${IMAGE_NAME}:unstable .'
                sh 'docker rm -f sentiment-unstable-test || true'
                sh 'docker run -d --name sentiment-unstable-test -p 5000:5000 ${DOCKERHUB_USER}/${IMAGE_NAME}:unstable'
                sh 'sleep 15'
            }
        }
        
        stage('Unit Test') {
            steps {
                echo 'Executing Stage 3: Running PyTest unit tests inside a containerized runtime environment...'
                sh 'docker run --rm --network host -v $(pwd)/tests:/app/tests ${DOCKERHUB_USER}/${IMAGE_NAME}:unstable pytest tests/test_api.py'
            }
        }
        
        stage('UI Test') {
            steps {
                echo 'Executing Stage 4: Running headless Selenium UI tests inside a containerized runtime environment...'
                sh '''
                docker run --rm --network host -v $(pwd):/workspace --entrypoint /bin/sh python:3.10-slim -c "
                    apt-get update && \
                    apt-get install -y chromium chromium-driver && \
                    pip install -r /workspace/requirements.txt && \
                    pytest /workspace/tests/test_ui.py
                "
                '''
            }
        }
        
        stage('Build and Push') {
            steps {
                echo 'Executing Stage 5: Building stable/unstable distribution artifacts and pushing to DockerHub...'
                withCredentials([usernamePassword(credentialsId: "${DOCKERHUB_CREDENTIALS_ID}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                    
                    // Fixed: Using valid Groovy comments out here or standard shell comments inside triple quotes
                    sh '''
                    mkdir -p stable_context
                    cp requirements.txt stable_context/
                    git fetch origin stable-fallback
                    git show origin/stable-fallback:app.py > stable_context/app.py
                    if [ -d templates ]; then cp -r templates stable_context/; fi
                    
                    echo 'FROM python:3.10-slim\\nWORKDIR /app\\nCOPY requirements.txt .\\nRUN pip install --no-cache-dir -r requirements.txt\\nCOPY app.py .\\nCOPY templates/ templates/\\nRUN mkdir -p /app/logs\\nEXPOSE 5000\\nCMD ["python", "app.py"]' > stable_context/Dockerfile
                    
                    docker build -t ${DOCKERHUB_USER}/${IMAGE_NAME}:stable stable_context/
                    '''
                    
                    sh 'docker push ${DOCKERHUB_USER}/${IMAGE_NAME}:unstable'
                    sh 'docker push ${DOCKERHUB_USER}/${IMAGE_NAME}:stable'
                }
            }
        }
        
        stage('Deploy to Minikube') {
            steps {
                echo 'Executing Stage 6: Orchestrating application resources onto the local Minikube cluster...'
                sh 'kubectl apply -f k8s/pvc.yaml'
                sh 'kubectl apply -f k8s/blue-deployment.yaml'
                sh 'kubectl apply -f k8s/green-deployment.yaml'
                sh 'kubectl apply -f k8s/service.yaml'
            }
        }
    }
    
    post {
        always {
            echo 'Cleaning up ephemeral local runtime test engines...'
            sh 'docker rm -f sentiment-unstable-test || true'
        }
    }
}
