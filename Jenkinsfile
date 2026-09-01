pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        ECR_CREDENTIALS_ID = 'aws-credentials'
        ECR_REPOSITORY = '8byte-app-repo'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Build and Push to ECR') {
            steps {
                script {
                    withAWS(region: env.AWS_REGION, credentials: env.ECR_CREDENTIALS_ID) {
                        
                        // 1. Fetch ECR Repository URI safely using single quotes
                        def ecrUri = sh(script: 'aws ecr describe-repositories --repository-names ${ECR_REPOSITORY} --query "repositories[0].repositoryUri" --output text', returnStdout: true).trim()
                        
                        // 2. Login to Amazon ECR
                        sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ecrUri}"

                        // 3. Build and Push Docker image
                        sh "docker build -t ${ecrUri}:${IMAGE_TAG} ."
                        sh "docker push ${ecrUri}:${IMAGE_TAG}"
                        sh "docker tag ${ecrUri}:${IMAGE_TAG} ${ecrUri}:latest"
                        sh "docker push ${ecrUri}:latest"
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully! Docker image pushed to ECR.'
        }
        failure {
            echo 'Pipeline failed during execution.'
        }
    }
}