# --------------------------------------------------
# Jenkins EC2 Infrastructure - Tech Challenge 2
# --------------------------------------------------

data "aws_ami" "jenkins_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# --------------------------------------------------
# Jenkins IAM role
# --------------------------------------------------

resource "aws_iam_role" "jenkins_role" {
  name = "tech2-jenkins-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ec2.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Project = "TechChallenge2"
  }
}

# --------------------------------------------------
# Jenkins ECR permissions
# --------------------------------------------------

resource "aws_iam_role_policy" "jenkins_ecr_policy" {
  name = "tech2-jenkins-ecr-policy"
  role = aws_iam_role.jenkins_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "ecr:GetAuthorizationToken"
        ]

        Resource = "*"
      },
      {
        Effect = "Allow"

        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]

        Resource = "arn:aws:ecr:us-east-1:418043655481:repository/tech2-flask-app"
      }
    ]
  })
}

# --------------------------------------------------
# Jenkins EKS permissions
# --------------------------------------------------

resource "aws_iam_role_policy" "jenkins_eks_policy" {
  name = "tech2-jenkins-eks-policy"
  role = aws_iam_role.jenkins_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Action = [
        "eks:DescribeCluster"
      ]

      Resource = aws_eks_cluster.tech2_cluster.arn
    }]
  })
}

# Grant Jenkins Kubernetes access through EKS
resource "aws_eks_access_entry" "jenkins" {
  cluster_name  = aws_eks_cluster.tech2_cluster.name
  principal_arn = aws_iam_role.jenkins_role.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "jenkins" {
  cluster_name  = aws_eks_cluster.tech2_cluster.name
  principal_arn = aws_iam_role.jenkins_role.arn

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"

  access_scope {
    type       = "namespace"
    namespaces = ["default"]
  }

  depends_on = [
    aws_eks_access_entry.jenkins
  ]
}

# Enable AWS Systems Manager access
resource "aws_iam_role_policy_attachment" "jenkins_ssm" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "tech2-jenkins-instance-profile"
  role = aws_iam_role.jenkins_role.name
}

# --------------------------------------------------
# Jenkins security group
# --------------------------------------------------

resource "aws_security_group" "jenkins_sg" {
  name_prefix = "tech2-jenkins-sg-"
  description = "Security group for Tech Challenge 2 Jenkins"

  vpc_id = aws_vpc.tech2_vpc.id

  egress {
    description = "Outbound access for AWS and installation"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "tech2-jenkins-sg"
    Project = "TechChallenge2"
  }
}

variable "jenkins_admin_cidr" {
  description = "Trusted public IPv4 address with /32"
  type        = string

  validation {
    condition = (
      can(cidrhost(var.jenkins_admin_cidr, 0)) &&
      endswith(var.jenkins_admin_cidr, "/32")
    )

    error_message = "Specify one trusted IPv4 address with /32."
  }
}

resource "aws_vpc_security_group_ingress_rule" "jenkins_web" {
  security_group_id = aws_security_group.jenkins_sg.id

  description = "Jenkins web UI from trusted administrator IP"

  from_port   = 8080
  to_port     = 8080
  ip_protocol = "tcp"

  cidr_ipv4 = var.jenkins_admin_cidr
}

# --------------------------------------------------
# Jenkins installation
# --------------------------------------------------

locals {
  jenkins_user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    exec > >(tee -a /var/log/jenkins-bootstrap.log) 2>&1

    dnf update -y

    dnf install -y \
      java-21-amazon-corretto \
      git \
      docker \
      curl \
      wget \
      unzip

    # Docker
    systemctl enable --now docker

    # Jenkins repository
    curl -fsSL \
      https://pkg.jenkins.io/redhat-stable/jenkins.repo \
      -o /etc/yum.repos.d/jenkins.repo

    rpm --import \
      https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

    dnf install -y jenkins

    usermod -aG docker jenkins

    systemctl enable --now jenkins

    # AWS CLI v2
    if ! command -v aws >/dev/null 2>&1; then
      curl -fsSL \
        https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip \
        -o /tmp/awscliv2.zip

      cd /tmp
      unzip -q awscliv2.zip
      ./aws/install
    fi

    # kubectl compatible with Kubernetes 1.37
    KUBECTL_VERSION=$(curl -fsSL \
      https://dl.k8s.io/release/stable-1.37.txt)

    curl -fsSL \
      "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl" \
      -o /usr/local/bin/kubectl

    chmod +x /usr/local/bin/kubectl

    # Helm 3
    curl -fsSL \
      https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
      -o /tmp/get_helm.sh

    chmod 700 /tmp/get_helm.sh
    /tmp/get_helm.sh

    # Configure kubeconfig for Jenkins
    mkdir -p /var/lib/jenkins/.kube

    /usr/local/bin/aws eks update-kubeconfig \
      --region us-east-1 \
      --name tech2-eks-cluster \
      --kubeconfig /var/lib/jenkins/.kube/config

    chown -R jenkins:jenkins /var/lib/jenkins/.kube

    systemctl restart jenkins

    # Print installed tool versions
    /usr/local/bin/aws --version
    /usr/local/bin/kubectl version --client
    helm version
    docker --version

    echo "Jenkins bootstrap completed successfully"
  EOF
}

# --------------------------------------------------
# Jenkins EC2 instance
# --------------------------------------------------

resource "aws_instance" "jenkins" {
  ami           = data.aws_ami.jenkins_amazon_linux.id
  instance_type = "m7i-flex.large"

  subnet_id = aws_subnet.public_a.id

  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.jenkins_sg.id
  ]

  iam_instance_profile = aws_iam_instance_profile.jenkins_profile.name

  user_data = local.jenkins_user_data

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  depends_on = [
    aws_route_table_association.public_a,
    aws_iam_role_policy_attachment.jenkins_ssm
  ]

  tags = {
    Name    = "tech2-jenkins-server"
    Project = "TechChallenge2"
  }
}

# --------------------------------------------------
# Outputs
# --------------------------------------------------

output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "jenkins_url" {
  value = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "jenkins_role_arn" {
  value = aws_iam_role.jenkins_role.arn
}
