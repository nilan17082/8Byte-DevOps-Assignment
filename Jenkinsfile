pipeline {
    agent any

    tools {
        nodejs 'node18'
    }

    environment {
        AWS_REGION = 'us-east-1'

        // Jenkins credential ID
        ECR_CREDENTIALS_ID = 'aws-jenkins'

        // ECR
        ECR_REPOSITORY = '8byte-app-repo'

        // ECS
        ECS_CLUSTER = '8byte-cluster'
        ECS_SERVICE_STAGING = '8byte-app-service'

        // Docker image tag
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {

        // =========================================================
        // 1. CHECKOUT CODE
        // =========================================================

        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }


        // =========================================================
        // 2. INSTALL DEPENDENCIES & TEST
        // =========================================================

        stage('Install Dependencies & Test') {
            steps {
                sh '''
                    echo "Installing dependencies..."
                    npm install

                    echo "Running tests..."
                    npm test
                '''
            }
        }


        // =========================================================
        // 3. TEST AWS CREDENTIALS
        // =========================================================

        stage('Test AWS Credentials') {
            when {
                expression {
                    return env.GIT_BRANCH == 'origin/main' ||
                           env.GIT_BRANCH == 'main' ||
                           env.BRANCH_NAME == 'main' ||
                           env.GIT_COMMIT != null
                }
            }

            steps {
                script {

                    echo "Testing AWS credentials..."

                    withAWS(
                        region: env.AWS_REGION,
                        credentials: env.ECR_CREDENTIALS_ID
                    ) {

                        sh '''
                            echo "Checking AWS identity..."

                            aws sts get-caller-identity

                            echo "AWS authentication successful!"
                        '''
                    }
                }
            }
        }


        // =========================================================
        // 4. BUILD, SCAN & PUSH TO ECR
        // =========================================================

        stage('Build, Scan & Push to ECR') {
            when {
                expression {
                    return env.GIT_BRANCH == 'origin/main' ||
                           env.GIT_BRANCH == 'main' ||
                           env.BRANCH_NAME == 'main' ||
                           env.GIT_COMMIT != null
                }
            }

            steps {
                script {

                    withAWS(
                        region: env.AWS_REGION,
                        credentials: env.ECR_CREDENTIALS_ID
                    ) {

                        // -------------------------------------------------
                        // Get ECR Repository URI
                        // -------------------------------------------------

                        echo "Finding ECR repository..."

                        def ecrUri = sh(
                            script: """
                                aws ecr describe-repositories \
                                --repository-names ${env.ECR_REPOSITORY} \
                                --query 'repositories[0].repositoryUri' \
                                --output text
                            """,
                            returnStdout: true
                        ).trim()

                        env.ECR_URI = ecrUri

                        echo "ECR URI: ${env.ECR_URI}"
                        echo "Image Tag: ${env.IMAGE_TAG}"


                        // -------------------------------------------------
                        // Docker Build
                        // -------------------------------------------------

                        echo "Building Docker image..."

                        sh """
                            docker build \
                            -t ${env.ECR_URI}:${env.IMAGE_TAG} .
                        """


                        // -------------------------------------------------
                        // Trivy Security Scan
                        // -------------------------------------------------

                        echo "Scanning Docker image with Trivy..."

                        sh """
                            trivy image \
                            --exit-code 1 \
                            --severity HIGH,CRITICAL \
                            ${env.ECR_URI}:${env.IMAGE_TAG}
                        """


                        // -------------------------------------------------
                        // Login to ECR
                        // -------------------------------------------------

                        echo "Logging into Amazon ECR..."

                        sh """
                            aws ecr get-login-password \
                            --region ${env.AWS_REGION} | \
                            docker login \
                            --username AWS \
                            --password-stdin ${env.ECR_URI}
                        """


                        // -------------------------------------------------
                        // Push Versioned Image
                        // -------------------------------------------------

                        echo "Pushing image with build tag..."

                        sh """
                            docker push ${env.ECR_URI}:${env.IMAGE_TAG}
                        """


                        // -------------------------------------------------
                        // Tag Latest
                        // -------------------------------------------------

                        echo "Creating latest tag..."

                        sh """
                            docker tag \
                            ${env.ECR_URI}:${env.IMAGE_TAG} \
                            ${env.ECR_URI}:latest
                        """


                        // -------------------------------------------------
                        // Push Latest
                        // -------------------------------------------------

                        echo "Pushing latest image..."

                        sh """
                            docker push ${env.ECR_URI}:latest
                        """

                        echo "Docker image successfully pushed to ECR!"
                    }
                }
            }
        }


        // =========================================================
        // 5. DEPLOY TO STAGING ECS
        // =========================================================

        stage('Deploy to Staging (ECS)') {
            when {
                expression {
                    return env.GIT_BRANCH == 'origin/main' ||
                           env.GIT_BRANCH == 'main' ||
                           env.BRANCH_NAME == 'main' ||
                           env.GIT_COMMIT != null
                }
            }

            steps {
                script {

                    withAWS(
                        region: env.AWS_REGION,
                        credentials: env.ECR_CREDENTIALS_ID
                    ) {

                        echo "Deploying application to ECS staging..."

                        sh """
                            aws ecs update-service \
                            --cluster ${env.ECS_CLUSTER} \
                            --service ${env.ECS_SERVICE_STAGING} \
                            --force-new-deployment \
                            --region ${env.AWS_REGION}
                        """

                        echo "ECS staging deployment triggered successfully!"
                    }
                }
            }
        }


        // =========================================================
        // 6. PRODUCTION APPROVAL
        // =========================================================

        stage('Approval Gate: Production') {
            when {
                expression {
                    return env.GIT_BRANCH == 'origin/main' ||
                           env.GIT_BRANCH == 'main' ||
                           env.BRANCH_NAME == 'main' ||
                           env.GIT_COMMIT != null
                }
            }

            steps {

                input(
                    message: 'Staging deployment successful. Promote to Production?',
                    ok: 'Deploy to Prod'
                )
            }
        }


        // =========================================================
        // 7. DEPLOY TO PRODUCTION
        // =========================================================

        stage('Deploy to Production') {
            when {
                expression {
                    return env.GIT_BRANCH == 'origin/main' ||
                           env.GIT_BRANCH == 'main' ||
                           env.BRANCH_NAME == 'main' ||
                           env.GIT_COMMIT != null
                }
            }

            steps {

                echo "Deploying to Production..."

                /*
                 * Production deployment placeholder.
                 *
                 * When production ECS resources are available,
                 * uncomment and modify this:
                 *
                 * withAWS(
                 *     region: env.AWS_REGION,
                 *     credentials: env.ECR_CREDENTIALS_ID
                 * ) {
                 *
                 *     sh """
                 *         aws ecs update-service \
                 *         --cluster 8byte-cluster-prod \
                 *         --service 8byte-app-service-prod \
                 *         --force-new-deployment \
                 *         --region ${env.AWS_REGION}
                 *     """
                 * }
                 */

                echo "Production deployment stage completed."
            }
        }
    }


    // =============================================================
    // POST ACTIONS
    // =============================================================

    post {

        // ---------------------------------------------------------
        // SUCCESS
        // ---------------------------------------------------------

        success {
            echo '=========================================='
            echo 'Pipeline completed successfully!'
            echo '=========================================='
        }


        // ---------------------------------------------------------
        // FAILURE
        // ---------------------------------------------------------

        failure {

            echo '=========================================='
            echo 'Pipeline failed!'
            echo 'Attempting AWS SNS notification...'
            echo '=========================================='

            script {

                try {

                    withAWS(
                        region: env.AWS_REGION,
                        credentials: env.ECR_CREDENTIALS_ID
                    ) {

                        // Get AWS Account ID

                        def accountId = sh(
                            script: '''
                                aws sts get-caller-identity \
                                --query Account \
                                --output text
                            ''',
                            returnStdout: true
                        ).trim()


                        // Construct SNS Topic ARN

                        def snsTopicArn =
                            "arn:aws:sns:${env.AWS_REGION}:${accountId}:8byte-alerts-topic"


                        echo "Sending failure notification to SNS..."


                        // Publish SNS notification

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

                        echo "SNS notification sent successfully."
                    }

                } catch (Exception e) {

                    // Don't hide the original pipeline failure

                    echo "SNS notification failed."
                    echo "Reason: ${e.getMessage()}"
                }
            }
        }
    }
}