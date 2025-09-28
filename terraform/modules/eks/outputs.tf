output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.cluster.id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.cluster.arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.cluster.endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.cluster.certificate_authority[0].data
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

output "cluster_oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if IRSA is enabled"
  value       = var.enable_irsa ? aws_iam_openid_connect_provider.cluster_oidc[0].arn : null
}

output "node_group_arn" {
  description = "Amazon Resource Name (ARN) of the EKS Node Group"
  value       = aws_eks_node_group.node_group.arn
}

output "node_group_status" {
  description = "Status of the EKS Node Group"
  value       = aws_eks_node_group.node_group.status
}

output "cluster_role_arn" {
  description = "IAM role ARN associated with EKS cluster"
  value       = aws_iam_role.cluster_role.arn
}

output "node_group_role_arn" {
  description = "IAM role ARN associated with EKS node group"
  value       = aws_iam_role.node_group_role.arn
}

output "node_group_security_group_id" {
  description = "Security group ID for the EKS node group"
  value       = aws_security_group.node_group_sg.id
}

output "ecr_repository_url" {
  description = "ECR repository URL for container images"
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_repository_arn" {
  description = "ECR repository ARN"
  value       = aws_ecr_repository.app.arn
}

output "ecr_init_repository_url" {
  description = "ECR repository URL for init container images"
  value       = aws_ecr_repository.init.repository_url
}

output "ecr_init_repository_arn" {
  description = "ECR repository ARN for init container"
  value       = aws_ecr_repository.init.arn
}

output "parameter_store_role_arn" {
  description = "IAM role ARN for accessing Parameter Store"
  value       = var.enable_irsa ? aws_iam_role.parameter_store_role[0].arn : null
}