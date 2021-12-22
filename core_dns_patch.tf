# Connect to kubectl box and setup kubectl
resource "null_resource" "core_dns_patch" {
  provisioner "remote-exec" {
    inline = [
      "kubectl patch deployment coredns --namespace kube-system --type=json -p='[{\"op\": \"remove\", \"path\": \"/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type\"}]'"
    ]
    connection {
      type           = "ssh"
      user           = "ec2-user"
      host           = aws_eip.kubectl_eip.public_ip
      agent_identity = var.ssh_private_key_identity
      private_key = "${file("/Users/arif/.ssh/id_rsa")}"

    }
  }
  depends_on = [
  null_resource.sleep,
  aws_eks_cluster.main,
  null_resource.config_kubectl
  ]
}