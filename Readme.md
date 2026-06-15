

Markdown  
\# ☁️ Advanced Cloud Database Architecture on AWS

An enterprise-grade, fault-tolerant cloud infrastructure deployed entirely via Infrastructure as Code (Terraform). This project demonstrates the implementation of Distributed Systems principles, High Availability (HA), and advanced database performance tuning on Amazon Web Services (AWS).

**\*\*Developed for the Advanced Database Masters Subject\*\*** **\*\*Team:\*\*** Mazen Monib | Nourhan Kazem | Ahmed Ayman

\---

\#\# 🎯 Project Overview

This project provisions a highly secure, three-tier architecture on AWS designed to host a high-performance web application backed by a resilient PostgreSQL database. The infrastructure strictly separates concerns into public routing, private compute, and isolated data tiers across multiple Availability Zones to guarantee zero single points of failure.

\#\#\# 🛠️ Tech Stack & Tools  
\* **\*\*Cloud Provider:\*\*** Amazon Web Services (AWS)  
\* **\*\*Infrastructure as Code (IaC):\*\*** Terraform (v1.0.0+)  
\* **\*\*Database Engine:\*\*** PostgreSQL 16 (Amazon RDS)  
\* **\*\*Compute:\*\*** Auto Scaling EC2 Instances (Amazon Linux, Apache/httpd)  
\* **\*\*Networking:\*\*** Custom VPC, Application Load Balancer (ALB), NAT Gateways  
\* **\*\*State Management:\*\*** AWS S3 (Remote Backend)

\---

\#\# 📂 Repository Structure & File Declarations

The infrastructure code is highly modularized. Below is the exact breakdown of the repository files and their responsibilities:

\* **\*\*\`main.tf\`\*\***: The core networking and identity layer. Provisions the Custom VPC, Internet Gateway, 6 subnets across 2 AZs (Public, Private Compute, Isolated DB), NAT Gateways, Route Tables, and the EC2 IAM Instance Profile for SSM access.  
\* **\*\*\`rds.tf\`\*\***: The database core. Defines the DB Subnet Group, a Custom Parameter Group (tuned \`work\_mem\` and \`log\_min\_duration\_statement\`), the Primary Multi-AZ PostgreSQL instance, and an asynchronous Read Replica.  
\* **\*\*\`alb.tf\`\*\***: Provisions the Application Load Balancer to distribute incoming web traffic.  
\* **\*\*\`listener.tf\`\*\***: Configures the ALB to listen on HTTP port 80 and forward requests to the target group.  
\* **\*\*\`target-group.tf\`\*\***: Defines the health checks and grouping for the backend EC2 servers.  
\* **\*\*\`autoscaling.tf\`\*\***: Configures the Auto Scaling Group (ASG) to maintain 2 to 4 instances spanning the private compute subnets.  
\* **\*\*\`autoscaling-policy.tf\`\*\***: Implements a Target Tracking scaling policy based on \`ASGAverageCPUUtilization\` (target 70%).  
\* **\*\*\`launch-template.tf\`\*\***: The EC2 template defining the \`t3.micro\` instance type and injecting a \`user\_data\` bash script to automatically install and start the Apache web server upon boot.  
\* **\*\*\`Security.tf\`\*\***: The firewall rules. Defines strict Security Groups for the ALB (public HTTP), EC2 (HTTP only from ALB), and RDS (TCP 5432 only from EC2).  
\* **\*\*\`Variables.tf\`\*\***: Declares the required input variables like region, CIDR blocks, and sensitive DB credentials.  
\* **\*\*\`terraform.tfvars\`\*\***: Contains the actual localized values for the variables declared in \`Variables.tf\`.  
\* **\*\*\`providers.tf\`\*\***: Configures the required AWS provider versions and defines the AWS S3 Remote Backend for state management.  
\* **\*\*\`outputs.tf\`\*\***: Exports essential connection endpoints (ALB DNS name and RDS Endpoint) after deployment.  
\* **\*\*\`.gitignore\`\*\***: Prevents sensitive local state files and Terraform lock files from being accidentally committed to source control.  
\* **\*\*\`.terraform.lock.hcl\`\*\***: Ensures consistent provider versions (AWS v6.49.0) across all deployments.

\---

\#\# ⚙️ Adjustments for Reusability

To reuse this code for a new deployment or personal project, make the following adjustments:

1\. **\*\*Unique S3 Bucket Name:\*\*** S3 bucket names must be globally unique across all of AWS. Open \`providers.tf\` and change \`bucket \= "advanced-db-project"\` to a unique bucket name that you own (e.g., \`my-unique-tf-state-bucket-123\`).  
2\. **\*\*Database Credentials:\*\*** Open \`terraform.tfvars\` and update \`db\_username\` and \`db\_password\` to your own secure credentials. *\*(Note: Do not commit sensitive passwords to public repositories).\**  
3\. **\*\*AMI IDs:\*\*** The \`image\_id \= "ami-0152204c1a187337c"\` in \`launch-template.tf\` is specific to \`us-east-1\`. If deploying to a different region, update this to a valid Amazon Linux 2 AMI for your target region.

\---

\#\# 🚀 Deployment Steps

This project uses an **\*\*AWS S3 Remote Backend\*\***. Because you need an S3 bucket to store the state, but Terraform is actively managing your infrastructure, follow this specific "local-to-remote" deployment sequence:

\#\#\# 1\. Temporarily Disable Remote State  
Open \`providers.tf\` and **\*\*comment out\*\*** the entire \`backend "s3"\` block:  
\`\`\`hcl  
\# backend "s3" {  
\#   bucket \= "advanced-db-project"  
\#   key    \= "infrastructure/terraform.tfstate"  
\#   region \= "us-east-1"  
\# }

### **2\. Initialize and Plan Locally**

Initialize Terraform to download the necessary AWS provider plugins locally. Then, run a plan to preview the infrastructure:

Bash  
terraform init  
terraform plan

*Review the output carefully to ensure the VPC, EC2s, and RDS instances are configured as expected.*

### **3\. Enable Remote State and Migrate**

Now that your infrastructure is deployed and your S3 bucket exists, secure the state file in the cloud for team collaboration.  
**Uncomment** the backend "s3" block in providers.tf, then run the migration command:

Bash  
terraform init \-migrate-state

*Terraform will ask if you want to copy the existing state to the new S3 backend. Type yes. Your state is now safely hosted in AWS.*

### **4\. Provision the Infrastructure**

Apply the configuration. This builds the entire AWS environment:

Bash  
terraform apply

*Type yes when prompted.*

### **5\. Access the Application**

Once the deployment finishes, use the outputs provided in your terminal:

* Copy the **alb\_dns\_name** into your web browser to see the auto-scaled Apache servers.  
* Use the **rds\_endpoint** in your preferred database client (like pgAdmin or DBeaver) to connect to the PostgreSQL instance.

## **🧹 Clean Up**

To destroy the infrastructure and prevent ongoing AWS charges, run:

Bash  
terraform destroy

## **🏆 Architecture Highlights**

By decoupling the architecture, enforcing strict network boundaries, implementing database read/write splitting, and managing it all through code, this project serves as a robust blueprint for modern, highly available cloud infrastructures.