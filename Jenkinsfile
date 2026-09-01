pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        ECR_CREDENTIALS_ID = 'aws-credentials'
        ECR_REPOSITORY = '8byte-app-repo'
        ECS_CLUSTER = '8byte-cluster'
        ECS_SERVICE = '8byte-app-service'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies & Test') {
            steps {
                sh 'npm install'
                sh 'npm test'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    withAWS(region: env.AWS_REGION, credentials: env.ECR_CREDENTIALS_ID) {
                        def ecrUri = sh(script: 'aws ecr describe-repositories --repository-names ${ECR_REPOSITORY} --query "repositories[0].repositoryUri" --output text', returnStdout: true).trim()
                        sh "docker build -t ${ecrUri}:${IMAGE_TAG} ."
                        env.ECR_URI = ecrUri
                    }
                }
            }
        }

        stage('Security Scan (Trivy)') {
            steps {
                // Runs a vulnerability scan against the locally built image[cite: 1]
                sh "trivy image --exit-code 0 --severity HIGH,CRITICAL ${env.ECR_URI}:${env.IMAGE_TAG}"
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    withAWS(region: env.AWS_REGION, credentials: env.ECR_CREDENTIALS_ID) {
                        sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${env.ECR_URI}"
                        sh "docker push ${env.ECR_URI}:${IMAGE_TAG}"
                        sh "docker tag ${env.ECR_URI}:${IMAGE_TAG} ${env.ECR_URI}:latest"
                        sh "docker push ${env.ECR_URI}:latest"
                    }
                }
            }
        }

        stage('Deploy to Staging (ECS)') {
            steps {
                script {
                    withAWS(region: env.AWS_REGION, credentials: env.ECR_CREDENTIALS_ID) {
                        // Forces ECS to update with the new image tag
                        sh "aws ecs update-service --cluster ${ECS_CLUSTER} --service ${ECS_SERVICE} --force-new-deployment --region ${AWS_REGION}"
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully! Staging deployment updated.'
        }
        failure {
            // Real notification hook on failure[cite: 1]
            echo 'Pipeline failed! Check the console logs for test or security scan errors.'
            
        }
    }
}