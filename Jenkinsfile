pipeline {
    agent any
    
    tools {
        nodejs 'node18' 
    }

    environment {
        AWS_REGION = 'us-east-1'
        ECR_CREDENTIALS_ID = 'aws-credentials'
        ECR_REPOSITORY = '8byte-app-repo'
        // Assuming your terraform provisioned one cluster, we use it for staging here.
        // In a real setup, you'd have a separate prod cluster.
        ECS_CLUSTER = '8byte-cluster'
        ECS_SERVICE_STAGING = '8byte-app-service' 
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies & Test') {
            // This runs on EVERY branch and Pull Request
            steps {
                sh 'npm install'
                sh 'npm test'
            }
        }

        stage('Build, Scan & Push to ECR') {
            // This and all subsequent stages ONLY run when merged to main
            when {
                branch 'main'
            }
            steps {
                script {
                    withAWS(region: env.AWS_REGION, credentials: env.ECR_CREDENTIALS_ID) {
                        def ecrUri = sh(script: 'aws ecr describe-repositories --repository-names ${ECR_REPOSITORY} --query "repositories[0].repositoryUri" --output text', returnStdout: true).trim()
                        env.ECR_URI = ecrUri
                        
                        // Build
                        sh "docker build -t ${ecrUri}:${IMAGE_TAG} ."
                        
                        // Scan
                        sh "trivy image --exit-code 1 --severity HIGH,CRITICAL ${ecrUri}:${IMAGE_TAG}"
                        
                        // Push
                        sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ecrUri}"
                        sh "docker push ${ecrUri}:${IMAGE_TAG}"
                        sh "docker tag ${ecrUri}:${IMAGE_TAG} ${ecrUri}:latest"
                        sh "docker push ${ecrUri}:latest"
                    }
                }
            }
        }

        stage('Deploy to Staging (ECS)') {
            when {
                branch 'main'
            }
            steps {
                script {
                    withAWS(region: env.AWS_REGION, credentials: env.ECR_CREDENTIALS_ID) {
                        sh "aws ecs update-service --cluster ${ECS_CLUSTER} --service ${ECS_SERVICE_STAGING} --force-new-deployment --region ${AWS_REGION}"
                    }
                }
            }
        }

        stage('Approval Gate: Production') {
            when {
                branch 'main'
            }
            steps {
                // This pauses the pipeline indefinitely until a user clicks "Proceed" in the Jenkins UI
                input message: 'Staging deployment successful. Promote to Production?', ok: 'Deploy to Prod'
            }
        }

        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                echo "Deploying to Production cluster... (Placeholder for Prod ECS service update)"
                // If you had a prod cluster provisioned, the command would go here:
                // sh "aws ecs update-service --cluster ${ECS_CLUSTER}-prod --service ${ECS_SERVICE_STAGING}-prod --force-new-deployment --region ${AWS_REGION}"
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed! Triggering email notification via AWS SNS...'
            script {
                // Reuse the AWS credentials already configured for ECR
                withAWS(region: env.AWS_REGION, credentials: env.ECR_CREDENTIALS_ID) {
                    // Dynamically fetch the AWS Account ID to construct the SNS Topic ARN
                    def accountId = sh(script: 'aws sts get-caller-identity --query Account --output text', returnStdout: true).trim()
                    def snsTopicArn = "arn:aws:sns:${env.AWS_REGION}:${accountId}:8byte-alerts-topic"
                    
                    // Publish a real message to the SNS topic you created in Terraform
                    sh """
                        aws sns publish \
                        --topic-arn ${snsTopicArn} \
                        --subject "🚨 Jenkins Pipeline Failed: Build #${env.BUILD_NUMBER}" \
                        --message "The Jenkins CI/CD pipeline failed.\nJob: ${env.JOB_NAME}\nBuild: ${env.BUILD_NUMBER}\nPlease check the Jenkins console logs." \
                        --region ${env.AWS_REGION}
                    """
                }
            }
        }
    }
}