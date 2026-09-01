pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        ECR_CREDENTIALS_ID = 'aws-credentials' // Name of your credentials ID stored in Jenkins
        ECR_REPOSITORY = '8byte-app-repo'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Authenticate & Login to ECR') {
            steps {
                script {
                    // Pulls AWS credentials from Jenkins credential manager
                    withAWS(region: env.AWS_REGION, credentials: env.ECR_CREDENTIALS_ID) {
                        sh "aws ecr get-login-password --region ${env.AWS_REGION} | docker login --username AWS --password-stdin $(aws ecr describe-repositories --repository-names ${env.ECR_REPOSITORY} --query 'repositories[0].repositoryUri' --output text | cut -d'/' -f1)"
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    appRepoUri = sh(script: "aws ecr describe-repositories --repository-names ${env.ECR_REPOSITORY} --query 'repositories[0].repositoryUri' --output text", returnStdout: true).trim()
                    
                    app = docker.build("${appRepoUri}:${env.IMAGE_TAG}")
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    appRepoUri = sh(script: "aws ecr describe-repositories --repository-names ${env.ECR_REPOSITORY} --query 'repositories[0].repositoryUri' --output text", returnStdout: true).trim()
                    
                    app.push("${env.IMAGE_TAG}")
                    app.push("latest")
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