output "cluster_ca_certificate" {
  value = aws_eks_cluster.EKS.certificate_authority[0].data
}