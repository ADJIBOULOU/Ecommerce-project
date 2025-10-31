# Terraform configuration file for development environment

# AWS Region
aws_region = "us-west-2"

# Project Configuration
project_name = "ecommerce-platform"
environment  = "dev"
owner        = "DevOps Team"

# VPC Configuration
vpc_cidr               = "10.2.0.0/16"
enable_nat_gateway     = true
single_nat_gateway     = true   # Single NAT gateway for cost savings in dev
enable_flow_logs       = false  # Disabled for cost savings in dev
flow_logs_retention_days = 7     # Reduced retention for cost optimization
create_db_subnet_group = true

# EKS Configuration
cluster_version                      = "1.29"
cluster_endpoint_private_access      = true
cluster_endpoint_public_access       = true
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]  # Open for dev - restrict for prod
cluster_enabled_log_types           = ["api", "audit"]  # Minimal logging for dev
cluster_log_retention_days          = 7

# Node Groups Configuration - Optimized for development
node_groups = {
  general = {
    instance_types              = ["t3.medium", "t3.large"]
    ami_type                   = "AL2_x86_64"
    capacity_type              = "SPOT"  # Use spot instances for cost savings
    disk_size                  = 30
    desired_size               = 2
    max_size                   = 4
    min_size                   = 1
    max_unavailable_percentage = 25
    tags = {
      NodeGroupType = "general"
      Environment   = "dev"
    }
  }
}

# EKS Add-ons Configuration
enable_vpc_cni_addon     = true
enable_coredns_addon     = true
enable_kube_proxy_addon  = true
enable_ebs_csi_addon     = true

# IAM Configuration
enable_external_dns = false