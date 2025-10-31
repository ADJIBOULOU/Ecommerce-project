# Outputs for EKS E-commerce Platform - Development Environment

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

# EKS Outputs
output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = module.eks.cluster_id
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = module.eks.cluster_iam_role_arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_primary_security_group_id" {
  description = "The cluster primary security group ID created by the EKS cluster"
  value       = module.eks.cluster_primary_security_group_id
}

output "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  value       = module.eks.cluster_version
}

output "cluster_status" {
  description = "Status of the EKS cluster. One of `CREATING`, `ACTIVE`, `DELETING`, `FAILED`"
  value       = module.eks.cluster_status
}

# Node Group Outputs
output "node_groups" {
  description = "Map of EKS node groups"
  value       = module.eks.node_groups
}

# IAM Outputs
output "cluster_service_role_arn" {
  description = "ARN of the EKS cluster service role"
  value       = module.iam.cluster_service_role_arn
}

output "node_group_role_arn" {
  description = "ARN of the EKS node group role"
  value       = module.iam.node_group_role_arn
}

output "ebs_csi_role_arn" {
  description = "ARN of the EBS CSI driver role"
  value       = module.iam.ebs_csi_role_arn
}

output "alb_controller_role_arn" {
  description = "ARN of the ALB controller role"
  value       = module.iam.alb_controller_role_arn
}

output "cluster_autoscaler_role_arn" {
  description = "ARN of the cluster autoscaler role"
  value       = module.iam.cluster_autoscaler_role_arn
}

# OIDC Provider Outputs
output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider"
  value       = module.eks.oidc_provider_arn
}

output "oidc_provider_url" {
  description = "The URL of the identity provider"
  value       = module.eks.oidc_provider_url
}

# Connection Information
output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_id}"
}

# Useful commands
output "useful_commands" {
  description = "Useful commands for managing the EKS cluster"
  value = {
    update_kubeconfig = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_id}"
    get_nodes        = "kubectl get nodes"
    get_pods         = "kubectl get pods --all-namespaces"
    cluster_info     = "kubectl cluster-info"
  }
}