pipeline {
    agent any
    options {
        // Prevent concurrent race conditions
        disableConcurrentBuilds()
    }
    environment {
        DOCKER = "\"C:\\Users\\HP\\AppData\\Local\\Programs\\DockerDesktop\\resources\\bin\\docker.exe\""
        IMAGE_NAME = "orderhub"
        APP_VERSION = "1.0.0"
        DEPLOY_PORT = "5000"
    }
    stages {
        stage('Checkout') {
            steps {
                echo "1. Checking out source repository..."
                checkout scm
            }
        }

        stage('Unit Test') {
            steps {
                echo "2. Running Unit Tests inside isolated Python container..."
                bat "${DOCKER} run --rm -v \"%WORKSPACE%:/app\" -w /app python:3.12-slim sh -c \"pip install --no-cache-dir -r requirements.txt && pytest tests/\""
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def shortSha = bat(script: '@git rev-parse --short HEAD 2>nul || echo local', returnStdout: true).trim()
                    env.GIT_SHA = shortSha ? shortSha.split('\r?\n').last().trim() : "local"
                    env.IMMUTABLE_TAG = "${BUILD_NUMBER}-${env.GIT_SHA}"
                }
                echo "3. Building Docker image with immutable tag: ${IMAGE_NAME}:${IMMUTABLE_TAG}"
                bat "${DOCKER} build -t ${IMAGE_NAME}:${IMMUTABLE_TAG} ."
            }
        }

        stage('Test Docker Image') {
            steps {
                echo "4. Testing built Docker image artifact..."
                bat "${DOCKER} run --rm ${IMAGE_NAME}:${IMMUTABLE_TAG} pytest tests/"
            }
        }

        stage('Tag & Push') {
            steps {
                echo "5. Tagging image and simulating push to registry..."
                bat "${DOCKER} tag ${IMAGE_NAME}:${IMMUTABLE_TAG} ${IMAGE_NAME}:latest"
            }
        }

        stage('Manual Approval') {
            when {
                branch 'main'
            }
            steps {
                echo "6. Awaiting operator confirmation for production promotion..."
                input message: "Approve deployment to production?", ok: "Deploy"
            }
        }

        stage('Deploy') {
            steps {
                echo "=========================================================="
                echo "Deploying OrderHub to Production on Port ${DEPLOY_PORT}"
                echo "Application Version : ${APP_VERSION}"
                echo "Git Commit          : ${env.GIT_SHA}"
                echo "Docker Image        : ${IMAGE_NAME}:${IMMUTABLE_TAG}"
                echo "Jenkins Build Number: ${BUILD_NUMBER}"
                echo "=========================================================="

                // Stop previous container and deploy the newly built immutable tag on port 5000
                bat "@${DOCKER} stop orderhub 2>nul & verify >nul"
                bat "@${DOCKER} rm orderhub 2>nul & verify >nul"
                bat "${DOCKER} run -d --name orderhub -p ${DEPLOY_PORT}:8080 -e APP_VERSION=${APP_VERSION} -e BUILD_NUMBER=${BUILD_NUMBER} -e GIT_COMMIT=${env.GIT_SHA} ${IMAGE_NAME}:${IMMUTABLE_TAG}"
            }
        }

        stage('Smoke Test') {
            steps {
                echo "8. Verifying production endpoints on port ${DEPLOY_PORT}..."
                bat "curl -s http://localhost:5000/health"
                bat "curl -s http://localhost:5000/version"
            }
        }
    }

    post {
        always {
            echo "Pipeline run completed."
        }
        success {
            echo "SUCCESS: OrderHub successfully deployed release ${IMAGE_NAME}:${IMMUTABLE_TAG} on port 5000."
        }
        failure {
            echo "FAILURE: Pipeline execution failed."
        }
        aborted {
            echo "ABORTED: Production deployment was rejected by the operator."
        }
    }
}