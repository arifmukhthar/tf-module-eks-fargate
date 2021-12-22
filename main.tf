## CLUSTER PROVISIONING RESOURCE
resource "aws_eks_cluster" "main" {
  name     = "${var.bc_env}-${var.bc_app_name}"
  role_arn = aws_iam_role.eks_cluster_role.arn

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_config {
    subnet_ids = concat(var.pub_subnet_ids, var.priv_subnet_ids)
  }

  timeouts {
    delete = "30m"
  }

  depends_on = [
    aws_cloudwatch_log_group.eks_cluster,
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSServicePolicy
  ]
}


# IAM POLICIES AND ROLES TO ATTACH TO THE EKS CLUSTER
resource "aws_iam_policy" "AmazonEKSClusterCloudWatchMetricsPolicy" {
  name   = "${var.bc_env}-${var.bc_app_name}-AmazonEKSClusterCloudWatchMetricsPolicy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "cloudwatch:PutMetricData"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "AmazonEKSClusterNLBPolicy" {
  name   = "${var.bc_env}-${var.bc_app_name}-AmazonEKSClusterNLBPolicy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "elasticloadbalancing:*",
                "ec2:CreateSecurityGroup",
                "ec2:Describe*"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_iam_role" "eks_cluster_role" {
  name                  = "${var.bc_env}-${var.bc_app_name}-eks-cluster-role"
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

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSCloudWatchMetricsPolicy" {
  policy_arn = aws_iam_policy.AmazonEKSClusterCloudWatchMetricsPolicy.arn
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSCluserNLBPolicy" {
  policy_arn = aws_iam_policy.AmazonEKSClusterNLBPolicy.arn
  role       = aws_iam_role.eks_cluster_role.name
}

# CLOUDWATCH GROUP FOR EKS CLUSTER TO STREAM LOGS TO
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.bc_app_name}-${var.bc_env}/cluster"
  retention_in_days = 30

  tags = {
    Name        = "${var.bc_app_name}-${var.bc_env}-eks-cloudwatch-log-group"
    Environment = var.bc_env
  }
}

