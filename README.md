# 8Byte DevOps Engineering Assignment

This repository contains the complete infrastructure, application, and CI/CD code for a scalable, secure, and monitored cloud deployment on AWS.

##  Architecture Overview

The infrastructure is provisioned using **Terraform** and follows AWS best practices for high availability and security:
- **Networking (VPC):** Custom VPC with public subnets (for the Load Balancer) and private subnets (for the App and Database).
- **Remote State Backend:** Managed securely via an S3 bucket and a DynamoDB lock table.
- **Compute (ECS Fargate):** Serverless container hosting for the Node.js application, ensuring seamless scaling without managing EC2 instances.
- **Database (RDS):** PostgreSQL database deployed in private subnets with strict Security Group rules and database credentials secured via AWS Secrets Manager.
- **Security:** Principle of least privilege enforced via IAM execution roles and tiered Security Groups.

##  CI/CD Pipeline (Jenkins)

Deployment automation is handled via a `Jenkinsfile` that executes the following functional stages sequentially upon a new push to the repository:
1. **Checkout Code:** Pulls the latest source code from the GitHub repository.
2. **Install Dependencies & Test:** Installs Node.js dependencies and executes integration tests against the API endpoints (`/health` and `/api/data`) using **Jest** and **Supertest**.
3. **Build Docker Image:** Containerizes the application and dynamically retrieves the ECR repository URI via the AWS CLI.
4. **Security Scan (Trivy):** Runs a local vulnerability scan against the built Docker image checking for HIGH and CRITICAL security vulnerabilities.
5. **Push to ECR:** Authenticates with AWS and pushes the container image (tagged with the build number and `latest`) to Amazon ECR.
6. **Deploy to Staging (ECS):** Automatically forces a new deployment on the AWS ECS Fargate service to run the updated container version.
7. **Notifications:** Post-actions configured to log and report pipeline success or failure statuses.

##  Monitoring & Logging (CloudWatch)

Centralized observability is configured directly via Terraform:
- **Log Groups:** Captures Application logs and Load Balancer access logs with a managed retention policy.
- **Dashboards:** 
  - *Infra & App Dashboard:* Tracks ECS CPU, Memory utilization, and ALB request/error metrics.
  - *Database Dashboard:* Tracks RDS CPU and active database connections.

##  How to Deploy

1. Ensure AWS CLI, Docker, and Terraform are installed and configured.
2. Navigate to the `terraform` directory: `cd terraform`
3. Initialize the directory: `terraform init`
4. Review the plan: `terraform plan`
5. Apply the infrastructure: `terraform apply`