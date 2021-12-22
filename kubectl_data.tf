data "aws_ami" "kubectl_image_lookup" {
  most_recent = true
  name_regex  = "amzn2.*"
  owners      = ["amazon"]
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_iam_policy_document" "kubectl_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = [
        "eks.amazonaws.com",
        "ec2.amazonaws.com"
      ]
      type = "Service"
    }
  }
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${var.account_id}:root"]
      type        = "AWS"
    }
  }
}

data "aws_iam_policy_document" "kubectl_iam_policy" {
  statement {
    actions   = ["sts:AssumeRole"]
    effect    = "Allow"
    resources = [aws_iam_role.kubectl_role.arn]
  }
  statement {
    actions   = ["eks:*"]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    actions   = ["iam:PassRole"]
    effect    = "Allow"
    resources = ["*"]
    condition {
      test     = "StringEquals"
      values   = ["eks.amazonaws.com"]
      variable = "iam:PassedToService"
    }
  }
}
