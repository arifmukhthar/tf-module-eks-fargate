
locals {
  suffix       = "${var.bc_env}_${var.bc_app_name}"
  kubectl_name = "kubectl_${local.suffix}"
  all_tags = merge(
    {
      "bounded_context" = var.bc_name
      "Name"            = local.kubectl_name
      "env"             = var.bc_env
    },
    var.bc_vpc_generic_tags,
    var.bc_vpc_defined_tags
  )
}

resource "aws_security_group" "kubectl_sg" {
  name        = local.kubectl_name
  description = "kubectl security group: allows inbound from world on port 22"
  vpc_id      = var.vpc_id
  tags        = local.all_tags

  ingress {
    description = "Allow ssh connections from world"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "kubectl_role" {
  name                  = local.kubectl_name
  assume_role_policy    = data.aws_iam_policy_document.kubectl_policy.json
  force_detach_policies = true
  description           = "role for the kubectl box"
  tags                  = local.all_tags
}

resource "aws_iam_role_policy_attachment" "kubectl_role_attach_iam" {
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
  role       = aws_iam_role.kubectl_role.name
}

resource "aws_iam_role_policy" "kubectl_iam_policy" {
  name   = local.kubectl_name
  policy = data.aws_iam_policy_document.kubectl_iam_policy.json
  role   = aws_iam_role.kubectl_role.id
}

resource "aws_iam_instance_profile" "kubectl_instance_profile" {
  name = local.kubectl_name
  role = aws_iam_role.kubectl_role.name
}

resource "aws_instance" "kubectl" {
  ami                    = data.aws_ami.kubectl_image_lookup.id
  instance_type          = var.instance_type
  tags                   = local.all_tags
  key_name               = var.ssh_key_name
  monitoring             = var.enable_detailed_instance_monitoring
  subnet_id              = var.pub_subnet_ids[0]
  volume_tags            = local.all_tags
  vpc_security_group_ids = [aws_security_group.kubectl_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.kubectl_instance_profile.name
  root_block_device {
    volume_size           = var.root_volume_size
    delete_on_termination = true
  }
}

# Create and assign the elastic IP
resource "aws_eip" "kubectl_eip" {
  vpc      = true
  instance = aws_instance.kubectl.id
  tags     = local.all_tags
}

resource "null_resource" "sleep" {
  provisioner "local-exec" {
    command = "sleep 120"
  }
}

# Connect to kubectl box and setup kubectl
resource "null_resource" "config_kubectl" {
  provisioner "remote-exec" {
    inline = [
      "sudo yum -y update",
      "sudo yum -y install nc awscli vim",
      "curl -LO https://storage.googleapis.com/kubernetes-release/release/v${var.kubectl_version}/bin/linux/amd64/kubectl",
      "chmod +x kubectl",
      "sudo mv kubectl /usr/local/bin/kubectl",
      "mkdir /home/ec2-user/.aws",
      "echo \"[default]\nregion=${var.bc_region}\nrole_arn=${aws_iam_role.kubectl_role.arn}\ncredential_source=Ec2InstanceMetadata\" > /home/ec2-user/.aws/config",
      "chown -R ec2-user:ec2-user /home/ec2-user/.aws",
      "export CALLER=\"$(aws sts get-caller-identity --query 'Arn'|sed 's/\\\"//g')\"",
      "export ROLE=\"$(aws iam get-role --role-name ${var.assume_role_name} --query 'Role.Arn'|sed 's/\\\"//g')\"",
      "export NROLE=\"$(aws iam get-role --role-name ${aws_iam_role.kubectl_role.name} --query 'Role.Arn'|sed 's/\\\"//g')\"",
      "export CROLE=\"$(aws iam get-role --role-name ${aws_iam_role.eks_cluster_role.name} --query 'Role.Arn'|sed 's/\\\"//g')\"",
      "aws iam update-assume-role-policy --role-name ${var.assume_role_name} --policy-document \"{\\\"Version\\\":\\\"2012-10-17\\\",\\\"Statement\\\":[{\\\"Effect\\\":\\\"Allow\\\",\\\"Principal\\\":{\\\"AWS\\\":[\\\"arn:aws:iam::467788488715:root\\\",\\\"$CALLER\\\"]},\\\"Action\\\":\\\"sts:AssumeRole\\\"}]}\"",
      "sleep 5",
      "aws sts assume-role --role-arn $ROLE --role-session-name test",
      "aws eks update-kubeconfig --name ${aws_eks_cluster.main.name} --role-arn $ROLE",
      "sleep 5",
      "kubectl get configmaps aws-auth -n kube-system -o yaml > aws_auth.yaml",
      "sed -i \"/      username/a \\    - rolearn: $NROLE\\n      username: kubectl-instance\\n      groups:\\n       - system:masters\" aws_auth.yaml",
      "kubectl apply -f aws_auth.yaml",
      "rm -rf ~/.kube",
      "aws eks update-kubeconfig --name ${aws_eks_cluster.main.name} --role-arn $NROLE",
      "aws iam update-assume-role-policy --role-name ${var.assume_role_name} --policy-document \"{\\\"Version\\\":\\\"2012-10-17\\\",\\\"Statement\\\":[{\\\"Effect\\\":\\\"Allow\\\",\\\"Principal\\\":{\\\"AWS\\\":\\\"arn:aws:iam::467788488715:root\\\"},\\\"Action\\\":\\\"sts:AssumeRole\\\"}]}\""
    ]
    connection {
      type           = "ssh"
      user           = "ec2-user"
      host           = aws_eip.kubectl_eip.public_ip
      agent_identity = var.ssh_private_key_identity
    }
  }
  depends_on = [
      null_resource.sleep, 
      aws_eks_cluster.main
      ]
}
