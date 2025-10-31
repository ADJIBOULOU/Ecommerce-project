# Terraform configuration file for staging environment

# AWS Region
aws_region = "us-west-2"

# Project Configuration
project_name = "ecommerce-platform"
environment  = "staging"
owner        = "DevOps Team"

# VPC Configuration
vpc_cidr               = "10.3.0.0/16"
enable_nat_gateway     = true
single_nat_gateway     = false  # Use multiple NAT gateways for HA in staging
enable_flow_logs       = true   # Enable VPC flow logs for staging
flow_logs_retention_days = 14    # Increased retention for staging analysis
create_db_subnet_group = true

# EKS Configuration
cluster_version                      = "1.29"
cluster_endpoint_private_access      = true
cluster_endpoint_public_access       = true
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]  # Consider restricting for staging
cluster_enabled_log_types           = ["api", "audit", "authenticator", "controllerManager", "scheduler"]  # Enhanced logging for staging
cluster_log_retention_days          = 14

# Node Groups Configuration - Optimized for staging
node_groups = {
  general = {
    instance_types              = ["t3.medium", "t3.large", "t3.xlarge"]
    ami_type                   = "AL2_x86_64"
    capacity_type              = "ON_DEMAND"  # Use on-demand instances for stability
    disk_size                  = 40
    desired_size               = 3
    max_size                   = 6
    min_size                   = 2
    max_unavailable_percentage = 25
    tags = {
      NodeGroupType = "general"
      Environment   = "staging"
    }
  }
}

# EKS Add-ons Configuration
enable_vpc_cni_addon     = true
enable_coredns_addon     = true
enable_kube_proxy_addon  = true
enable_ebs_csi_addon     = true

# IAM Configuration
enable_external_dns = true  # Enable external DNS for staging