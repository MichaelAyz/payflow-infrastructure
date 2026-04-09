output "eks_cluster_name" {
  value = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "eks_cluster_ca" {
  value = aws_eks_cluster.main.certificate_authority[0].data
}

output "spoke_vpc_id" {
  value = aws_vpc.spoke.id
}

output "private_subnet_ids" {
  value = [for s in aws_subnet.private : s.id]
}

output "public_subnet_ids" {
  value = [for s in aws_subnet.public : s.id]
}

output "node_security_group_id" {
  value = aws_security_group.nodes.id
}

output "ecr_repository_urls" {
  value = { for k, v in aws_ecr_repository.microservices : k => v.repository_url }
}

output "alb_controller_irsa_arn" {
  value = aws_iam_role.alb_controller.arn
}

output "eso_irsa_arn" {
  value = aws_iam_role.eso.arn
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.eks.arn
}
