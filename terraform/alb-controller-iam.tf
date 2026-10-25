
# AWS Load Balancer Controller IAM configuration
# Tech Challenge 2

resource "aws_iam_policy" "alb_controller" {
  name        = "tech2-aws-load-balancer-controller-policy"
  description = "Permissions for AWS Load Balancer Controller on EKS"

  policy = file("${path.module}/alb-controller-policy.json")

  tags = {
    Project = "TechChallenge2"
  }
}

resource "aws_iam_role" "alb_controller" {
  name = "tech2-aws-load-balancer-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })

  tags = {
    Project = "TechChallenge2"
  }
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

output "alb_controller_role_arn" {
  description = "IAM role ARN for the AWS Load Balancer Controller"
  value       = aws_iam_role.alb_controller.arn
}
