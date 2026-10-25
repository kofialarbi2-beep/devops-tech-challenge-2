
# Discover the Auto Scaling Group created by the EKS managed node group
data "aws_autoscaling_groups" "tech2_nodes" {
  filter {
    name   = "tag:eks:cluster-name"
    values = [aws_eks_cluster.tech2_cluster.name]
  }

  filter {
    name   = "tag:eks:nodegroup-name"
    values = [aws_eks_node_group.tech2_nodes.node_group_name]
  }

  depends_on = [
    aws_eks_node_group.tech2_nodes
  ]
}

# Allow Cluster Autoscaler to discover the node group
resource "aws_autoscaling_group_tag" "autoscaler_enabled" {
  for_each = toset(data.aws_autoscaling_groups.tech2_nodes.names)

  autoscaling_group_name = each.value

  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = false
  }
}

resource "aws_autoscaling_group_tag" "autoscaler_cluster" {
  for_each = toset(data.aws_autoscaling_groups.tech2_nodes.names)

  autoscaling_group_name = each.value

  tag {
    key                 = "k8s.io/cluster-autoscaler/tech2-eks-cluster"
    value               = "owned"
    propagate_at_launch = false
  }
}
