# Terraform configuration file for production environment

# AWS Region
aws_region = "us-west-2"

# Project Configuration
project_name = "ecommerce-platform"
environment  = "prod"
owner        = "DevOps Team"

# VPC Configuration
vpc_cidr               = "10.0.0.0/16"
enable_nat_gateway     = true
single_nat_gateway     = false  # Use multiple NAT gateways for HA
enable_flow_logs       = true
flow_logs_retention_days = 30
create_db_subnet_group = true

# EKS Configuration
cluster_version                      = "1.29"
cluster_endpoint_private_access      = true
cluster_endpoint_public_access       = true
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]  # Restrict this in production
cluster_enabled_log_types           = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
cluster_log_retention_days          = 30

# Node Groups Configuration
node_groups = {
  general = {
    instance_types              = ["m5.large", "m5.xlarge"]
    ami_type                   = "AL2_x86_64"
    capacity_type              = "ON_DEMAND"
    disk_size                  = 50
    desired_size               = 3
    max_size                   = 10
    min_size                   = 1
    max_unavailable_percentage = 25
    tags = {
      NodeGroupType = "general"
      Environment   = "prod"
    }
  }
  
  compute_optimized = {
    instance_types              = ["c5.large", "c5.xlarge"]
    ami_type                   = "AL2_x86_64"
    capacity_type              = "SPOT"
    disk_size                  = 50
    desired_size               = 2
    max_size                   = 5
    min_size                   = 0
    max_unavailable_percentage = 25
    tags = {
      NodeGroupType = "compute-optimized"
      Environment   = "prod"
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