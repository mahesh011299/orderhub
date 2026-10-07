pipeline {
    agent any
    options {
        // Prevent concurrent build race conditions
        disableConcurrentBuilds()
    }
    environment {
        DOCKER = "\"C:\\Users\\HP\\AppData\\Local\\Programs\\DockerDesktop\\resources\\bin\\docker.exe\""
        REGISTRY = "localhost:5001"
        IMAGE_NAME = "orderhub"
        APP_VERSION = "1.0.0"
        DEPLOY_PORT = "5000"
    }
    stages {
        stage('Checkout') {
            steps {
                echo "1. Checking out source repository from GitHub..."
                checkout scm
            }
        }

        stage('Unit Test') {
            steps {
                echo "2. Running Unit Tests in isolated Python container..."
                bat "${DOCKER} run --rm -v \"%WORKSPACE%:/app\" -w /app -e PYTHONPATH=. python:3.12-slim sh -c \"pip install --no-cache-dir -r requirements.txt && python -m pytest tests/\""
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def shortSha = bat(script: '@git rev-parse --short HEAD 2>nul || echo local', returnStdout: true).trim()
                    env.GIT_SHA = shortSha ? shortSha.split('\r?\n').last().trim() : "local"
                    env.IMMUTABLE_TAG = "${BUILD_NUMBER}-${env.GIT_SHA}"
                    env.FULL_IMAGE = "${REGISTRY}/${IMAGE_NAME}:${env.IMMUTABLE_TAG}"
                }
                echo "3. Building Docker image: ${FULL_IMAGE}"
                bat "${DOCKER} build -t ${FULL_IMAGE} ."
            }
        }

        stage('Test Docker Image') {
            steps {
                echo "4. Testing containerized artifact..."
                bat "${DOCKER} run --rm -e PYTHONPATH=. ${FULL_IMAGE} python -m pytest tests/"
            }
        }

        stage('Push to Registry') {
            steps {
                echo "5. Pushing immutable artifact to Docker Registry (${REGISTRY})..."
                bat "${DOCKER} push ${FULL_IMAGE}"
            }
        }

        stage('Manual Approval') {
            when {
                branch 'main'
            }
            steps {
                echo "6. Awaiting operator confirmation..."
                input message: "Promote ${FULL_IMAGE} to production?", ok: "Deploy"
            }
        }

        stage('Deploy to Production Host') {
            steps {
                echo "=========================================================="
                echo "Deploying to Production Host from Registry"
                echo "Image               : ${FULL_IMAGE}"
                echo "Application Version : ${APP_VERSION}"
                echo "Git Commit          : ${env.GIT_SHA}"
                echo "Jenkins Build Number: ${BUILD_NUMBER}"
                echo "=========================================================="

                // Pull exact immutable image from registry and run the production container
                bat "${DOCKER} pull ${FULL_IMAGE}"
                bat "@${DOCKER} stop orderhub 2>nul & verify >nul"
                bat "@${DOCKER} rm orderhub 2>nul & verify >nul"
                bat "${DOCKER} run -d --name orderhub -p ${DEPLOY_PORT}:8080 -e APP_VERSION=${APP_VERSION} -e BUILD_NUMBER=${BUILD_NUMBER} -e GIT_COMMIT=${env.GIT_SHA} ${FULL_IMAGE}"
            }
        }

        stage('Smoke Test') {
            steps {
                echo "8. Verifying production container health on port ${DEPLOY_PORT}..."
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
            echo "SUCCESS: OrderHub deployed successfully on port 5000."
        }
        failure {
            echo "FAILURE: Pipeline execution failed."
        }
        aborted {
            echo "ABORTED: Production deployment was rejected by operator."
        }
    }
}