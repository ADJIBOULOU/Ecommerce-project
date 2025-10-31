# Variables for EKS E-commerce Platform - Production Environment

# General Configuration
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "ecommerce-platform"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "owner" {
  description = "Owner of the infrastructure"
  type        = string
  default     = "DevOps Team"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_nat_gateway" {
  description = "Should be true if you want to provision NAT Gateways for each of your private networks"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Should be true to provision a single shared NAT Gateway across all of your private networks"
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "CloudWatch log group retention in days for VPC flow logs"
  type        = number
  default     = 30
}

variable "create_db_subnet_group" {
  description = "Controls if database subnet group should be created"
  type        = bool
  default     = true
}

# EKS Configuration
variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "cluster_endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_enabled_log_types" {
  description = "List of EKS cluster log types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cluster_log_retention_days" {
  description = "CloudWatch log group retention in days for cluster logs"
  type        = number
  default     = 30
}

# Node Groups Configuration
variable "node_groups" {
  description = "Map of EKS node group configurations"
  type = map(object({
    instance_types               = list(string)
    ami_type                    = string
    capacity_type               = string
    disk_size                   = number
    desired_size                = number
    max_size                    = number
    min_size                    = number
    max_unavailable_percentage  = number
    tags                        = map(string)
  }))
  
  default = {
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
      }
    }
    
    compute = {
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
      }
    }
  }
}

# EKS Add-ons Configuration
variable "enable_vpc_cni_addon" {
  description = "Enable VPC CNI EKS add-on"
  type        = bool
  default     = true
}

variable "enable_coredns_addon" {
  description = "Enable CoreDNS EKS add-on"
  type        = bool
  default     = true
}

variable "enable_kube_proxy_addon" {
  description = "Enable kube-proxy EKS add-on"
  type        = bool
  default     = true
}

variable "enable_ebs_csi_addon" {
  description = "Enable EBS CSI EKS add-on"
  type        = bool
  default     = true
}

# IAM Configuration
variable "enable_external_dns" {
  description = "Enable External DNS IAM role"
  type        = bool
  default     = false
}