# IAM Module Outputs

output "cluster_service_role_arn" {
  description = "ARN of the EKS cluster service role"
  value       = aws_iam_role.cluster_service_role.arn
}

output "cluster_service_role_name" {
  description = "Name of the EKS cluster service role"
  value       = aws_iam_role.cluster_service_role.name
}

output "node_group_role_arn" {
  description = "ARN of the EKS node group role"
  value       = aws_iam_role.node_group_role.arn
}

output "node_group_role_name" {
  description = "Name of the EKS node group role"
  value       = aws_iam_role.node_group_role.name
}

output "ebs_csi_role_arn" {
  description = "ARN of the EBS CSI driver role"
  value       = var.oidc_provider_arn != "" ? aws_iam_role.ebs_csi_role[0].arn : null
}

output "alb_controller_role_arn" {
  description = "ARN of the ALB controller role"
  value       = var.oidc_provider_arn != "" ? aws_iam_role.alb_controller_role[0].arn : null
}

output "cluster_autoscaler_role_arn" {
  description = "ARN of the cluster autoscaler role"
  value       = var.oidc_provider_arn != "" ? aws_iam_role.cluster_autoscaler_role[0].arn : null
}

output "external_dns_role_arn" {
  description = "ARN of the external DNS role"
  value       = var.enable_external_dns && var.oidc_provider_arn != "" ? aws_iam_role.external_dns_role[0].arn : null
}