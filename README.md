

\# Tech Challenge 2 — Flask Application on AWS EKS



\## Overview



This project demonstrates deploying a containerized Python Flask application to Amazon Elastic Kubernetes Service (EKS) using Terraform, Docker, Amazon ECR, and Kubernetes.



\## Architecture



\- Terraform provisions AWS infrastructure.

\- Amazon VPC provides networking with two public subnets.

\- Amazon EKS hosts the Kubernetes cluster.

\- An EC2 managed node group runs the application.

\- Docker packages the Flask application.

\- Amazon ECR stores the container image.

\- Kubernetes Deployment manages the Flask pod.

\- Kubernetes ClusterIP Service provides internal access.

\- Kubernetes health probes monitor application health.



\## Technologies



\- Python 3

\- Flask

\- Docker

\- Terraform

\- AWS VPC

\- Amazon EKS

\- Amazon ECR

\- Amazon EC2

\- Kubernetes

\- AWS CLI

\- kubectl



\## Project Structure



&#x20;   Tech2/

&#x20;   ├── app/

&#x20;   │   ├── app.py

&#x20;   │   └── requirements.txt

&#x20;   ├── k8s/

&#x20;   │   ├── deployment.yaml

&#x20;   │   └── service.yaml

&#x20;   ├── terraform/

&#x20;   │   ├── eks.tf

&#x20;   │   ├── main.tf

&#x20;   │   ├── network.tf

&#x20;   │   ├── nodes.tf

&#x20;   │   ├── outputs.tf

&#x20;   │   └── providers.tf

&#x20;   ├── Dockerfile

&#x20;   ├── .gitignore

&#x20;   └── README.md



\## Prerequisites



\- AWS account with appropriate IAM permissions

\- AWS CLI configured

\- Terraform installed

\- Docker installed

\- kubectl installed



\## Infrastructure Deployment



Navigate to the Terraform directory:



&#x20;   cd terraform



Initialize Terraform:



&#x20;   terraform init



Review the infrastructure:



&#x20;   terraform plan



Deploy the infrastructure:



&#x20;   terraform apply



\## Build Docker Image



From the project root:



&#x20;   docker build -t tech2-flask-app .



\## Push Image to Amazon ECR



Authenticate Docker with ECR:



&#x20;   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 418043655481.dkr.ecr.us-east-1.amazonaws.com



Tag the image:



&#x20;   docker tag tech2-flask-app:latest 418043655481.dkr.ecr.us-east-1.amazonaws.com/tech2-flask-app:latest



Push the image:



&#x20;   docker push 418043655481.dkr.ecr.us-east-1.amazonaws.com/tech2-flask-app:latest



\## Configure Kubernetes Access



&#x20;   aws eks update-kubeconfig --region us-east-1 --name tech2-eks-cluster



The AWS identity running kubectl must have appropriate EKS access permissions.



\## Deploy Application



From the project root:



&#x20;   kubectl apply -f k8s/



Verify deployment:



&#x20;   kubectl get deployments

&#x20;   kubectl get pods

&#x20;   kubectl get services



\## Test Application



Forward the Kubernetes service to localhost:



&#x20;   kubectl port-forward service/tech2-flask-service 8080:80



Open:



&#x20;   http://localhost:8080/health



Expected response:



&#x20;   {"status":"healthy"}



\## Deployment Verification



The application was successfully deployed to Amazon EKS.



Verification confirmed:



\- Kubernetes Deployment: 1/1 ready

\- Flask pod: Running

\- Container restarts: 0

\- Health endpoint: HTTP 200

\- Response: {"status":"healthy"}



\## Security and Networking



\- AWS infrastructure is provisioned using Terraform.

\- Kubernetes uses IAM-integrated EKS access.

\- The application is exposed internally using a ClusterIP Service.

\- The application can be tested locally through kubectl port-forward.

\- Terraform state files and local credentials are excluded from Git.



\## Cleanup



AWS resources can incur charges while running.



To remove the Kubernetes application:



&#x20;   kubectl delete -f k8s/



To destroy Terraform-managed infrastructure:



&#x20;   cd terraform

&#x20;   terraform destroy



Review the Terraform destruction plan before approving it.



