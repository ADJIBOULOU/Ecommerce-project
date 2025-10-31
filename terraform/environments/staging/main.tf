# Main Terraform configuration for EKS E-commerce Platform - Staging Environment

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Uncomment and configure for remote state
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "eks-ecommerce/staging/terraform.tfstate"
  #   region         = "us-west-2"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
  
  # Exclude availability zones that don't support EKS
  exclude_names = ["us-west-2d"]
}

# Local values
locals {
  cluster_name = "${var.project_name}-${var.environment}-eks"
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.owner
    ManagedBy   = "terraform"
    CreatedAt   = "2025-10-20"
  }
}

# IAM roles will be created by the IAM module



# IAM Module - Basic roles (cluster and node group roles first)
module "iam" {
  source = "../../modules/iam"

  cluster_name        = local.cluster_name
  oidc_provider_arn   = ""  # Will be populated after EKS cluster is created
  oidc_provider_url   = ""  # Will be populated after EKS cluster is created
  enable_external_dns = var.enable_external_dns

  common_tags = local.common_tags
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  cluster_name       = local.cluster_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = data.aws_availability_zones.available.names

  enable_nat_gateway           = var.enable_nat_gateway
  single_nat_gateway          = var.single_nat_gateway
  enable_flow_logs            = var.enable_flow_logs
  flow_logs_retention_days    = var.flow_logs_retention_days
  create_db_subnet_group      = var.create_db_subnet_group

  common_tags = local.common_tags
}

# EKS Module
module "eks" {
  source = "../../modules/eks"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version

  vpc_id                               = module.vpc.vpc_id
  private_subnets                      = module.vpc.private_subnets
  public_subnets                       = module.vpc.public_subnets
  cluster_service_role_arn             = module.iam.cluster_service_role_arn
  node_group_role_arn                  = module.iam.node_group_role_arn
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  cluster_enabled_log_types           = var.cluster_enabled_log_types
  cluster_log_retention_days          = var.cluster_log_retention_days

  node_groups = var.node_groups

  enable_vpc_cni_addon     = var.enable_vpc_cni_addon
  enable_coredns_addon     = var.enable_coredns_addon
  enable_kube_proxy_addon  = var.enable_kube_proxy_addon
  enable_ebs_csi_addon     = var.enable_ebs_csi_addon

  common_tags = local.common_tags
}