resource "aws_eks_fargate_profile" "main" {
  for_each               = toset(var.namespaces)
  cluster_name           = aws_eks_cluster.main.name
  fargate_profile_name   = format("%s-fargate-%s", aws_eks_cluster.main.name, each.value)
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role.arn
  subnet_ids             = var.priv_subnet_ids

  selector {
    namespace = each.value
    labels    = var.labels
  }
}

resource "aws_iam_role_policy_attachment" "AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate_pod_execution_role.name
}

resource "aws_iam_role" "fargate_pod_execution_role" {
  name                  = "${var.bc_env}-${var.bc_app_name}-eks-fargate-pod-execution-role"
  force_detach_policies = true

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "eks.amazonaws.com",
          "eks-fargate-pods.amazonaws.com"
          ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}