
# IAM role for EKS EC2 worker nodes
resource "aws_iam_role" "eks_node_role" {
  name = "tech2-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project = "TechChallenge2"
  }
}

# EKS worker node permissions
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# ECR image pull permissions
resource "aws_iam_role_policy_attachment" "eks_ecr_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

# VPC CNI permissions
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Launch template for public subnet worker nodes
resource "aws_launch_template" "eks_nodes" {
  name_prefix = "tech2-eks-nodes-"

  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name    = "tech2-eks-worker"
      Project = "TechChallenge2"
    }
  }
}

# EKS managed worker node group
resource "aws_eks_node_group" "tech2_nodes" {
  cluster_name    = aws_eks_cluster.tech2_cluster.name
  node_group_name = "tech2-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn

  subnet_ids = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]

  instance_types = ["t3.small"]
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = aws_launch_template.eks_nodes.latest_version
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_ecr_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_route_table_association.public_a,
    aws_route_table_association.public_b
  ]

  tags = {
    Name    = "tech2-node-group"
    Project = "TechChallenge2"
  }
}
