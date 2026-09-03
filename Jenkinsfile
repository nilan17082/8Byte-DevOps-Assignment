pipeline {
    agent any

    tools {
        nodejs 'node18'
    }

    environment {
        AWS_REGION = 'us-east-1'

        // Jenkins credential ID
        ECR_CREDENTIALS_ID = 'aws-credentials'

        ECR_REPOSITORY = '8byte-app-repo'

        ECS_CLUSTER = '8byte-cluster'
        ECS_SERVICE_STAGING = '8byte-app-service'

        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {

        // =====================================================
        // 1. Checkout
        // =====================================================

        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }


        // =====================================================
        // 2. Install Dependencies & Test
        // =====================================================

        stage('Install Dependencies & Test') {
            steps {
                sh '''
                    npm install
                    npm test
                '''
            }
        }


        // =====================================================
        // 3. Test AWS Credentials
        // =====================================================

        stage('Test AWS Credentials') {
            when {
                branch 'main'
            }

            steps {
                script {
                    withAWS(
                        region: env.AWS_REGION,
                        credentials: env.ECR_CREDENTIALS_ID
                    ) {
                        sh '''
                            echo "Testing AWS authentication..."

                            aws sts get-caller-identity

                            echo "AWS authentication successful."
                        '''
                    }
                }
            }
        }


        // =====================================================
        // 4. Build, Scan & Push to ECR
        // =====================================================

        stage('Build, Scan & Push to ECR') {
            when {
                branch 'main'
            }

            steps {
                script {

                    withAWS(
                        region: env.AWS_REGION,
                        credentials: env.ECR_CREDENTIALS_ID
                    ) {

                        // -------------------------------------------------
                        // Get ECR repository URI
                        // -------------------------------------------------

                        def ecrUri = sh(
                            script: """
                                aws ecr describe-repositories \
                                --repository-names ${ECR_REPOSITORY} \
                                --query 'repositories[0].repositoryUri' \
                                --output text
                            """,
                            returnStdout: true
                        ).trim()

                        env.ECR_URI = ecrUri

                        echo "ECR Repository: ${env.ECR_URI}"
                        echo "Image Tag: ${env.IMAGE_TAG}"


                        // -------------------------------------------------
                        // Build Docker image
                        // -------------------------------------------------

                        sh """
                            docker build \
                            -t ${env.ECR_URI}:${env.IMAGE_TAG} .
                        """


                        // -------------------------------------------------
                        // Trivy Security Scan
                        // -------------------------------------------------

                        sh """
                            trivy image \
                            --exit-code 1 \
                            --severity HIGH,CRITICAL \
                            ${env.ECR_URI}:${env.IMAGE_TAG}
                        """


                        // -------------------------------------------------
                        // Login to ECR
                        // -------------------------------------------------

                        sh """
                            aws ecr get-login-password \
                            --region ${env.AWS_REGION} | \
                            docker login \
                            --username AWS \
                            --password-stdin ${env.ECR_URI}
                        """


                        // -------------------------------------------------
                        // Push versioned image
                        // -------------------------------------------------

                        sh """
                            docker push ${env.ECR_URI}:${env.IMAGE_TAG}
                        """


                        // -------------------------------------------------
                        // Tag latest
                        // -------------------------------------------------

                        sh """
                            docker tag \
                            ${env.ECR_URI}:${env.IMAGE_TAG} \
                            ${env.ECR_URI}:latest
                        """


                        // -------------------------------------------------
                        // Push latest
                        // -------------------------------------------------

                        sh """
                            docker push ${env.ECR_URI}:latest
                        """
                    }
                }
            }
        }


        // =====================================================
        // 5. Deploy to Staging ECS
        // =====================================================

        stage('Deploy to Staging (ECS)') {
            when {
                branch 'main'
            }

            steps {
                script {

                    withAWS(
                        region: env.AWS_REGION,
                        credentials: env.ECR_CREDENTIALS_ID
                    ) {

                        sh """
                            aws ecs update-service \
                            --cluster ${env.ECS_CLUSTER} \
                            --service ${env.ECS_SERVICE_STAGING} \
                            --force-new-deployment \
                            --region ${env.AWS_REGION}
                        """
                    }
                }
            }
        }


        // =====================================================
        // 6. Production Approval
        // =====================================================

        stage('Approval Gate: Production') {
            when {
                branch 'main'
            }

            steps {
                input(
                    message: 'Staging deployment successful. Promote to Production?',
                    ok: 'Deploy to Prod'
                )
            }
        }


        // =====================================================
        // 7. Production Deployment
        // =====================================================

        stage('Deploy to Production') {
            when {
                branch 'main'
            }

            steps {
                echo 'Deploying to Production cluster...'

                /*
                 * Production deployment placeholder.
                 *
                 * When you have a production ECS cluster/service:
                 *
                 * sh """
                 *     aws ecs update-service \
                 *     --cluster 8byte-cluster-prod \
                 *     --service 8byte-app-service-prod \
                 *     --force-new-deployment \
                 *     --region ${env.AWS_REGION}
                 * """
                 */
            }
        }
    }


    // =========================================================
    // POST ACTIONS
    // =========================================================

    post {

        success {
            echo 'Pipeline completed successfully!'
        }


        failure {
            echo 'Pipeline failed! Attempting AWS SNS notification...'

            script {

                try {

                    withAWS(
                        region: env.AWS_REGION,
                        credentials: env.ECR_CREDENTIALS_ID
                    ) {

                        def accountId = sh(
                            script: '''
                                aws sts get-caller-identity \
                                --query Account \
                                --output text
                            ''',
                            returnStdout: true
                        ).trim()

                        def snsTopicArn =
                            "arn:aws:sns:${env.AWS_REGION}:${accountId}:8byte-alerts-topic"


                        sh """
                            aws sns publish \
                            --topic-arn ${snsTopicArn} \
                            --subject "Jenkins Pipeline Failed: Build #${env.BUILD_NUMBER}" \
                            --message "The Jenkins CI/CD pipeline failed.
Job: ${env.JOB_NAME}
Build: ${env.BUILD_NUMBER}
Please check the Jenkins console logs." \
                            --region ${env.AWS_REGION}
                        """
                    }

                } catch (Exception e) {

                    // Don't hide the original pipeline failure
                    echo "SNS notification failed: ${e.getMessage()}"
                }
            }
        }
    }
}