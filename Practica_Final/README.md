# Project: Infrastructure Automation with Terraform and Ansible for PSS-TI
# Author: Ignacio de Lecea Jiménez

## Table of Contents

- [1. Prerequisites](#1-prerequisites)
  - [1.1. Development Environment](#11-development-environment)
  - [1.2. IaC Tools](#12-iac-tools)
  - [1.3. Cloud Provider](#13-cloud-provider)
  - [1.4. Network](#14-network)
  - [1.5. Additional Packages](#15-additional-packages)
  - [1.6. Exercise Requirements](#16-exercise-requirements)


- [2. Execution Steps](#2-execution-steps)
  - [2.1. Project Structure](#21-project-structure)
  - [2.2. Terraform Procedure](#22-terraform-procedure)
  - [2.3. Ansible Procedure](#23-ansible-procedure)


- [3. Integration Between Terraform and Ansible](#3-integration-between-terraform-and-ansible)

---

## 1. Prerequisites

### 1.1. Development Environment

- Vagrant virtual machine with CentOS Stream 9.

### 1.2. IaC Tools
Before running the deployment, ensure you have installed:
- Terraform (v1.5+ recommended)
- Ansible (v2.13+ recommended)

### 1.3. Cloud Provider

- Active AWS account in ap-south-1 region.
- Configured credentials.

### 1.4. Network

- Internet connectivity on the VM.
- SSH key with access to the EC2 instances
- Internet access from your machine to download packages and WordPres

### 1.5. Additional Packages

- Python3 and pip.
- Ansible packages for AWS.

## 2. Execution Steps
**Clone the repository:**
```
git clone  https://github.com/nachodele/PSS-Talent/tree/main/Practica_Final
```
**Deploy the infrastructure and configure the servers:**
```
Make deploy
```

### 2.1. Project Structure
The project is organized in a logical and ordered structure to facilitate integration and deployment:

### 2.2. Terraform Procedure

1. **S3 Bucket Generation:**  
   A bucket is created with a random suffix to ensure uniqueness and avoid conflicts. This is done first to prevent the chicken-and-egg problem.  
   The backend is configured to remotely manage the `.tfstate` file, ensuring security and project state persistence.

2. **Public Policy for S3 Bucket:**  
   A policy is created allowing any user to perform the `s3:GetObject` action on all objects within the bucket to enable controlled public access.

3. **Disable Public Access Block:**  
   Bucket settings are adjusted to allow public access according to the defined policy.

4. **Static Website Configuration for S3:**  
   The bucket is enabled as a static website, `index.html` and `error.html` files are uploaded, and an output is created to verify endpoint accessibility.

5. **Custom VPC Creation:**  
   A VPC with a specific CIDR range is defined.  
   Two public and two private subnets are created, each pair in different availability zones for high availability.

6. **NAT Gateway and Route Tables Configuration:**  
   A NAT Gateway is assigned to each public subnet using elastic IPs for fixed assignment.  
   Public route tables route traffic through the Internet Gateway, while private route tables route outbound traffic to the corresponding NAT Gateway.  
   This setup allows instances in private subnets to access the Internet (for updates or other services) without being exposed.

7. **EC2 Instances Definition:**  
   The AMI `ubuntu-focal-20.04-amd64-server-*` is chosen for its stability and wide use in web environments.  
   An instance is created in the public subnet for the webserver, allowing direct HTTP and HTTPS access.  
   Another instance is created in the private subnet for the database, ensuring security and isolation.  
   Since the database instance does not have a public IP, it cannot be accessed directly via SSH.  
   To connect to this instance, the webserver acts as a bastion host, making an SSH jump through it.  
   However, the direct connection from Ansible to the database using this method has not been fully achieved.

8. **Security Groups Configuration:**  
   - Web group: allows HTTP (80), HTTPS (443), and SSH (22) traffic from anywhere for accessibility and remote management.  
   - Database group: restricts access to the MySQL port (3306) only from the web group, ensuring strict security and access control.

### 2.3. Ansible Procedure

1. **Dynamic Inventory:**  
   The `aws_ec2` plugin is used to obtain the AWS instance inventory in real-time, facilitating automatic node management.

2. **Ansible Roles:**  
   - `webserver` role to install and configure Apache and WordPress.  
   - `database` role to install and configure MariaDB/MySQL.  
   Tasks are appropriately distributed to ensure correct service configuration and deployment.

3. **Validation:**  
   `ansible-inventory --graph` is run to verify the proper structure and availability of nodes in the dynamic inventory.

## 3. Integration Between Terraform and Ansible

The main integration between Terraform and Ansible is implemented through a Makefile that automates and orchestrates the entire deployment and configuration workflow.  
This script performs the following steps automatically:

1. Initializes Terraform in the corresponding directory, preparing the environment for application.  
2. Runs `terraform apply` with automatic approval to create all defined infrastructure.  
3. Pauses execution for 80 seconds to ensure EC2 instances are fully provisioned and accessible.  
4. Runs the Ansible playbook `site.yml` using a dynamic AWS-based inventory to configure deployed services.  
5. Provides a separate command to destroy created infrastructure using `terraform destroy`.

This way, Terraform handles the provisioning and creation of cloud resources, while Ansible takes care of detailed configuration of servers and applications once infrastructure is ready.  
The Makefile facilitates the coordinated sequence between both, allowing the entire process to be executed with a single command, increasing efficiency and minimizing human errors in manual integration.
