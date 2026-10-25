resource "aws_ecr_repository" "tech2_app" {
  name                 = "tech2-flask-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project   = "TechChallenge2"
    ManagedBy = "Terraform"
  }
}