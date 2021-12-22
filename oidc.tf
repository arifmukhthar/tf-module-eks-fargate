provider "external" {
  version = "~> 1.2"
}

data "tls_certificate" "cluster" {
  url = aws_eks_cluster.main.identity.0.oidc.0.issuer
}

resource "aws_iam_openid_connect_provider" "main" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = concat([data.tls_certificate.cluster.certificates.0.sha1_fingerprint], var.oidc_thumbprint_list)
  url             = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer

  depends_on = [
    aws_eks_cluster.main
  ]
}