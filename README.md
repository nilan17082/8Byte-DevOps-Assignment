# 8Byte DevOps Engineering Assignment

This repository contains the complete infrastructure, application, and CI/CD code for a scalable, secure, and monitored cloud deployment on AWS.

## 🏗️ Architecture Overview

The infrastructure is provisioned using **Terraform** and follows AWS best practices for high availability and security:
- **Networking (VPC):** Custom VPC with public subnets (for the Load Balancer) and private subnets (for the App and Database).
- **Compute (ECS Fargate):** Serverless container hosting for the Node.js application, ensuring seamless scaling without managing EC2 instances.
- **Database (RDS):** PostgreSQL database deployed in private subnets with strict Security Group rules.
- **Security:** Principle of least privilege enforced via IAM roles and tiered Security Groups.

## 🚀 CI/CD Pipeline (Jenkins)

Deployment automation is handled via a `Jenkinsfile` that triggers on pull requests and merges:
1. **Test:** Runs unit and integration tests automatically.
2. **Security Scan:** Uses Trivy to scan the Docker image for critical/high vulnerabilities.
3. **Build & Push:** Compiles the Docker image and pushes it to AWS ECR.
4. **Deploy:** Updates the ECS staging service.
5. **Approval:** Requires manual approval before promoting to Production.
6. **Notifications:** Configured to alert on pipeline failures.

## 📊 Monitoring & Logging (CloudWatch)

Centralized observability is configured directly via Terraform:
- **Log Groups:** Captures Application logs and Load Balancer access logs with a 7-day retention policy.
- **Dashboards:** 
  - *Infra & App Dashboard:* Tracks ECS CPU and Memory utilization.
  - *Database Dashboard:* Tracks RDS CPU and active database connections.

## 🛠️ How to Deploy

1. Ensure AWS CLI and Terraform are installed and configured.
2. Navigate to the `terraform` directory: `cd terraform`
3. Initialize the directory: `terraform init`
4. Review the plan: `terraform plan`
5. Apply the infrastructure: `terraform apply`