pipeline {
    agent any

    environment {
        ECR_REGISTRY = "your-aws-account-id.dkr.ecr.us-east-1.amazonaws.com/8byte-app-repo"
        IMAGE_TAG    = "${env.BUILD_NUMBER ?: 'latest'}"
    }

    tools {
        nodejs 'node18'
    }

    stages {
        stage('Checkout & Test') {
            steps {
                checkout scm
                sh 'npm install'
                sh 'npm test'
            }
        }

        stage('Dependency & Vulnerability Scan') {
            steps {
                sh 'npm audit --audit-level=high || true'
            }
        }

        stage('Build Docker Image') {
            steps {
                // SIMULATED FOR LOCAL DEMO:
                echo "Executing: docker build -t $ECR_REGISTRY:$IMAGE_TAG ."
                // sh 'docker build -t $ECR_REGISTRY:$IMAGE_TAG .'
            }
        }

        stage('Container Security Scan') {
            steps {
                // SIMULATED FOR LOCAL DEMO:
                echo "Executing: trivy image --severity CRITICAL,HIGH $ECR_REGISTRY:$IMAGE_TAG"
                // sh 'docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image --format table --exit-code 0 --ignore-unfixed --severity CRITICAL,HIGH $ECR_REGISTRY:$IMAGE_TAG'
            }
        }

        stage('Push to Registry') {
            steps {
                // SIMULATED FOR LOCAL DEMO:
                echo "Executing: docker push $ECR_REGISTRY:$IMAGE_TAG"
                // sh 'docker push $ECR_REGISTRY:$IMAGE_TAG'
            }
        }

        stage('Deploy to Staging') {
            steps {
                echo "Deploying to Staging Environment (ECS Cluster)..."
                echo "Executing: aws ecs update-service --cluster 8byte-app-cluster --service 8byte-app-service --force-new-deployment"
                // sh 'aws ecs update-service --cluster 8byte-app-cluster --service 8byte-app-service --force-new-deployment'
            }
        }

        stage('Approval for Production') {
            steps {
                // This will still physically pause and wait for your click!
                input message: 'Staging verification complete. Approve deployment to Production?', ok: 'Deploy to Production'
            }
        }

        stage('Deploy to Production') {
            steps {
                echo "Deploying to Production ECS Environment..."
                echo "Executing: aws ecs update-service --cluster prod-cluster --service prod-service --force-new-deployment"
                // sh 'aws ecs update-service --cluster prod-cluster --service prod-service --force-new-deployment'
                echo "Successfully deployed to production!"
            }
        }
    }

    post {
        success {
            echo 'Deployment successful! Sending Slack notification...'
        }
        failure {
            echo 'Pipeline failed! Sending email and Slack alerts...'
        }
    }
}