# Deployment Guide

This guide provides step-by-step instructions for deploying the EKS E-commerce Platform using the multi-branch deployment strategy.

## 🚀 Branch-Based Deployment Strategy

### Environment Mapping

| Branch | Environment | Cluster Name | Namespace | Auto-Deploy |
|--------|-------------|--------------|-----------|-------------|
| `develop` | Development | `ecommerce-platform-dev-eks-*` | `dev` | ✅ |
| `master` | Staging | `ecommerce-platform-staging-eks` | `staging` | ✅ |
| `release` | Production | `ecommerce-platform-prod-eks` | `production` | ✅ (with approval) |

### Deployment Triggers

- **Push to develop** → Deploys to development environment
- **Push to master** → Deploys to staging environment  
- **Push to release** → Deploys to production environment
- **Manual workflow** → Deploy to any environment via GitHub Actions

### Environment Configuration Differences

| Configuration | Development | Staging | Production |
|---------------|-------------|---------|------------|
| **Node Groups** | t3.medium/large (Spot) | m5.large/xlarge + c5.large/xlarge | m5.large/xlarge + c5.large/xlarge |
| **Desired Capacity** | 2 nodes | 2-3 nodes | 3+ nodes |
| **NAT Gateway** | Single (cost saving) | Single | Multiple (HA) |
| **Log Retention** | 7 days | 14 days | 30 days |
| **Flow Logs** | Disabled | Disabled | Enabled |
| **Monitoring Resources** | 200m CPU, 1Gi RAM | 400m CPU, 1.5Gi RAM | 800m CPU, 3Gi RAM (HA) |
| **Monitoring Retention** | 7 days | 14 days | 30 days |
| **Scrape Interval** | 30s (relaxed) | 15s (moderate) | 10s (frequent) |

> **💡 Note**: The development environment uses a random 4-character suffix (like `dfsl`) in the cluster name to prevent naming conflicts. Use `terraform output cluster_name` to get the exact cluster name.

## Prerequisites

Before you begin, ensure you have the following tools installed and configured:

### Required Tools

1. **AWS CLI** (v2.0+)
   ```bash
   # Install AWS CLI
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   
   # Configure AWS credentials
   aws configure
   ```

2. **Terraform** (v1.0+)
   ```bash
   # Install Terraform
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

3. **kubectl** (v1.29+)
   ```bash
   # Install kubectl
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
   ```

4. **Helm** (v3.12+)
   ```bash
   # Install Helm
   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
   ```

### AWS Permissions

Your AWS user/role needs the following permissions:
- EC2 full access (for VPC, subnets, security groups)
- EKS full access (for cluster management)
- IAM full access (for roles and policies)
- CloudWatch full access (for logging and monitoring)
- ECR full access (for container registry)

## Environment Setup

### 1. Clone Repository

```bash
git clone <your-repository-url>
cd ecommerce-platform
```

### 2. Configure Variables

Edit the appropriate environment configuration file:

```bash
# For production deployment
cd terraform/environments/prod
cp terraform.tfvars.example terraform.tfvars
```

Update `terraform.tfvars` with your specific values:

```hcl
# AWS Configuration
aws_region = "us-west-2"
project_name = "ecommerce-platform"
environment = "prod"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"
enable_nat_gateway = true
single_nat_gateway = false

# EKS Configuration
cluster_version = "1.29"
cluster_endpoint_public_access_cidrs = ["YOUR_IP_ADDRESS/32"]  # Restrict access

# Node Groups
node_groups = {
  general = {
    instance_types = ["m5.large", "m5.xlarge"]
    desired_size = 3
    max_size = 10
    min_size = 1
  }
}
```

## Infrastructure Deployment

### 1. Choose Your Environment

Select the appropriate environment directory based on your deployment target:

```bash
# For development environment
cd terraform/environments/dev

# For staging environment  
cd terraform/environments/staging

# For production environment
cd terraform/environments/prod
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Plan Infrastructure

```bash
terraform plan -out=tfplan
```

Review the plan carefully to ensure all resources are correct, paying special attention to:

- Resource naming (dev environment includes random suffix)
- Node group configurations
- Network settings (NAT gateway configuration)
- Monitoring and logging settings

### 4. Apply Infrastructure

```bash
terraform apply tfplan
```

This will create:

- VPC with public and private subnets
- EKS cluster with managed node groups
- IAM roles and policies
- Security groups and network ACLs
- CloudWatch log groups

### 5. Configure kubectl

Configure kubectl to access your newly created cluster:

```bash
# For production environment
aws eks update-kubeconfig --region us-west-2 --name ecommerce-platform-prod-eks

# For staging environment  
aws eks update-kubeconfig --region us-west-2 --name ecommerce-platform-staging-eks

# For development environment (get the actual cluster name with random suffix)
cd terraform/environments/dev
DEV_CLUSTER_NAME=$(terraform output -raw cluster_name)
aws eks update-kubeconfig --region us-west-2 --name $DEV_CLUSTER_NAME
```

Verify cluster access:

```bash
kubectl get nodes
kubectl get namespaces
```

## Application Deployment

### Step 1: One-Time Setup (Global Configuration)

Before deploying to any environment, perform these one-time setup tasks:

```bash
# Add required Helm repositories (only needed once globally)
helm repo add eks https://aws.github.io/eks-charts || echo "Repository already exists, continuing..."
helm repo update

# Verify repositories are added
helm repo list
```

### Step 2: Deploy Base Infrastructure with Kustomize

Deploy environment-specific Kubernetes configurations:

```bash
# Navigate to project root
cd /Users/sandeepcc/workspace/project

# Deploy environment-specific configurations using Kustomize
# For production:
kubectl apply -k kubernetes/environments/prod/

# For staging:
kubectl apply -k kubernetes/environments/staging/

# For development:
kubectl apply -k kubernetes/environments/dev/

# Verify namespace creation and base components
kubectl get namespaces
kubectl get pods -A
```

### Step 3: Deploy ALB Ingress Controller

Deploy the AWS Load Balancer Controller for ingress management:

```bash
# Create IAM service account (environment-specific)
# For production:
eksctl create iamserviceaccount \
  --cluster=ecommerce-platform-prod-eks \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole-prod \
  --attach-policy-arn=arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess \
  --approve

# Install ALB controller via Helm
helm install aws-load-balancer-controller-prod eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=ecommerce-platform-prod-eks \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

# Verify ALB controller deployment
kubectl get deployment -n kube-system aws-load-balancer-controller
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

> **Note**: For other environments, replace the cluster name and role name appropriately (e.g., use the dynamic cluster name for development environment).

### Step 4: Verify Cluster Autoscaler

The Cluster Autoscaler is deployed automatically via Kustomize configurations:

```bash
# Verify Cluster Autoscaler is running
kubectl get deployment cluster-autoscaler -n kube-system
kubectl get pods -n kube-system -l app=cluster-autoscaler

# Check autoscaler logs for proper configuration
kubectl logs -n kube-system deployment/cluster-autoscaler --tail=50

# Verify autoscaler can discover node groups
kubectl describe configmap cluster-autoscaler-status -n kube-system
```

### 4. Deploy Monitoring Stack

The monitoring stack includes environment-specific Prometheus and Grafana configurations with appropriate resource allocation.

```bash
# Create monitoring namespace if not exists
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Create environment-specific Prometheus ConfigMap
kubectl create configmap prometheus-config-prod \
  --from-file=prometheus.yml=monitoring/environments/prometheus-prod.yml \
  -n monitoring \
  --dry-run=client -o yaml | kubectl apply -f -

# Create environment-specific Grafana ConfigMap
kubectl apply -f monitoring/grafana/config-prod.yaml

# Deploy environment-specific Prometheus (production)
kubectl apply -f monitoring/prometheus/deployment-prod.yaml

# Deploy environment-specific Grafana (production)
kubectl apply -f monitoring/grafana/deployment-prod.yaml

# Create Grafana admin secret
kubectl create secret generic grafana-admin-secret \
  --from-literal=password=admin123 \
  -n monitoring \
  --dry-run=client -o yaml | kubectl apply -f -

# Verify monitoring deployment
kubectl get pods -n monitoring
kubectl get services -n monitoring
kubectl get pvc -n monitoring

# Check Prometheus is scraping targets
kubectl port-forward svc/prometheus-prod -n monitoring 9090:9090
# Visit http://localhost:9090/targets to verify
```

### Step 6: Deploy Microservices

Deploy the e-commerce microservices using Helm charts with environment-specific configurations:

#### Prepare Image Registry

```bash
# Update image repository in all values files (replace with your ECR registry)
find helm-charts -name "values*.yaml" -exec sed -i 's/your-registry/YOUR_ECR_REGISTRY/g' {} \;
```

#### Deploy Services by Environment

**For Production Environment:**

```bash
# Set environment variables
export NAMESPACE="production"
export IMAGE_TAG="${IMAGE_TAG:-latest}"

# Deploy services with production-specific configurations
helm install product-catalog ./helm-charts/product-catalog \
  --namespace $NAMESPACE \
  --values helm-charts/product-catalog/values-prod.yaml \
  --set image.tag=$IMAGE_TAG

helm install user-accounts ./helm-charts/user-accounts \
  --namespace $NAMESPACE \
  --values helm-charts/user-accounts/values-prod.yaml \
  --set image.tag=$IMAGE_TAG

# Services without prod-specific values use defaults (optimized for production)
for service in shopping-cart order-management payment-processing; do
  helm install $service ./helm-charts/$service \
    --namespace $NAMESPACE \
    --set image.tag=$IMAGE_TAG
done

# Verify deployments
kubectl get pods -n $NAMESPACE
kubectl get services -n $NAMESPACE
kubectl get hpa -n $NAMESPACE
```

## Verification

### 1. Check Pod Status

```bash
kubectl get pods -n production
kubectl get pods -n monitoring
```

### 2. Check Services

```bash
kubectl get services -n production
kubectl get ingress -n production
```

### 3. Check Autoscaling

```bash
kubectl get hpa -n production
kubectl get nodes
```

### 4. Access Monitoring

```bash
# Port forward to Grafana (environment-specific service)
# For production:
kubectl port-forward svc/grafana-prod -n monitoring 3000:3000

# For staging:
kubectl port-forward svc/grafana-staging -n monitoring 3000:3000

# For development:
kubectl port-forward svc/grafana-dev -n monitoring 3000:3000

# Access Grafana at http://localhost:3000
# Default credentials: admin/admin123

# Port forward to Prometheus (environment-specific service)
# For production:
kubectl port-forward svc/prometheus-prod -n monitoring 9090:9090

# Access Prometheus at http://localhost:9090
```

## Post-Deployment Configuration

### 1. SSL Certificates

Create SSL certificates in AWS Certificate Manager:

```bash
# Request certificate via AWS CLI
aws acm request-certificate \
  --domain-name api.yourcompany.com \
  --validation-method DNS \
  --region us-west-2
```

Update ingress annotations with certificate ARN:

```yaml
alb.ingress.kubernetes.io/certificate-arn: "arn:aws:acm:us-west-2:ACCOUNT:certificate/CERT-ID"
```

### 2. DNS Configuration

Configure your domain DNS to point to the ALB:

```bash
# Get ALB DNS name
kubectl get ingress -n production
```

Create CNAME records pointing to the ALB DNS name.

### 3. Monitoring Alerts

Configure CloudWatch alarms and SNS topics:

```bash
# Create SNS topic for alerts
aws sns create-topic --name ecommerce-alerts

# Subscribe to topic
aws sns subscribe \
  --topic-arn arn:aws:sns:us-west-2:ACCOUNT:ecommerce-alerts \
  --protocol email \
  --notification-endpoint your-email@company.com
```

## Monitoring Stack Deployment

### Understanding Environment-Specific Monitoring

Each environment has tailored monitoring configurations:

| Component | Development | Staging | Production |
|-----------|-------------|---------|------------|
| **Prometheus CPU** | 200m | 400m | 800m |
| **Prometheus Memory** | 1Gi | 1.5Gi | 3Gi |
| **Grafana CPU** | 200m | 300m | 500m |
| **Grafana Memory** | 512Mi | 768Mi | 1.5Gi |
| **Retention** | 7 days | 14 days | 30 days |
| **Replicas** | 1 | 1 | 2 (HA) |
| **Scrape Interval** | 30s | 15s | 10s |

### Deploy Monitoring for Your Environment

Choose the appropriate monitoring deployment based on your environment:

```bash
# Production monitoring deployment
kubectl apply -f monitoring/prometheus/deployment-prod.yaml
kubectl apply -f monitoring/grafana/deployment-prod.yaml

# Staging monitoring deployment  
kubectl apply -f monitoring/prometheus/deployment-staging.yaml
kubectl apply -f monitoring/grafana/deployment-staging.yaml

# Development monitoring deployment
kubectl apply -f monitoring/prometheus/deployment-dev.yaml
kubectl apply -f monitoring/grafana/deployment-dev.yaml
```

> **Important**: Each environment uses its own ConfigMaps and service names to ensure complete isolation.

## Environment-Specific Deployments

### Development Environment

**Note**: Development environment uses a random 4-character suffix for the cluster name to avoid conflicts.

```bash
# Alternative: List existing EKS clusters to find the dev cluster name
aws eks list-clusters --region us-west-2 --query 'clusters[?contains(@, `dev`)]'
# Deploy infrastructure
cd terraform/environments/dev
terraform init
terraform apply

# Get the actual cluster name with suffix
DEV_CLUSTER_NAME=$(terraform output -raw cluster_name)
echo "Dev cluster name: $DEV_CLUSTER_NAME"

# Configure kubectl for dev cluster (example: ecommerce-platform-dev-eks-dfsl)
aws eks update-kubeconfig --region us-west-2 --name $DEV_CLUSTER_NAME

# Deploy base configurations (run from project root)
cd /Users/sandeepcc/workspace/project && kubectl apply -k kubernetes/environments/dev/

# Deploy ALB Ingress Controller for dev environment
# Note: Helm repo is already added globally, no need to add again
eksctl create iamserviceaccount \
  --cluster=$DEV_CLUSTER_NAME \
  --namespace=kube-system \
  --name=aws-load-balancer-controller-dev \
  --role-name AmazonEKSLoadBalancerControllerRole-dev \
  --attach-policy-arn=arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess \
  --approve \

helm install aws-load-balancer-controller-dev eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$DEV_CLUSTER_NAME \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller-dev

# Deploy microservices with development values
helm install product-catalog ./helm-charts/product-catalog \
  --namespace dev \
  --values helm-charts/product-catalog/values-dev.yaml

helm install user-accounts ./helm-charts/user-accounts \
  --namespace dev \
  --values helm-charts/user-accounts/values-dev.yaml

# Deploy remaining services (these don't have dev-specific values, use default)
for service in shopping-cart order-management payment-processing; do
  helm install $service ./helm-charts/$service \
    --namespace dev \
    --set image.tag=${IMAGE_TAG:-latest}
done

# Deploy monitoring stack for development
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl create configmap prometheus-config-dev \
  --from-file=prometheus.yml=monitoring/environments/prometheus-dev.yml \
  -n monitoring \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f monitoring/grafana/config-dev.yaml
kubectl apply -f monitoring/prometheus/deployment-dev.yaml
kubectl apply -f monitoring/grafana/deployment-dev.yaml
kubectl create secret generic grafana-admin-secret \
  --from-literal=password=admin123 \
  -n monitoring \
  --dry-run=client -o yaml | kubectl apply -f -
```

### Staging Environment

```bash
# Deploy infrastructure
cd terraform/environments/staging
terraform init
terraform apply

# Configure kubectl for staging cluster
aws eks update-kubeconfig --region us-west-2 --name ecommerce-platform-staging-eks

# Deploy base configurations (run from project root)
cd /Users/sandeepcc/workspace/project && kubectl apply -k kubernetes/environments/staging/

# Deploy ALB Ingress Controller for staging environment  
# Note: Helm repo is already added globally, no need to add again
eksctl create iamserviceaccount \
  --cluster=ecommerce-platform-staging-eks \
  --namespace=kube-system \
  --name=aws-load-balancer-controller-staging \
  --role-name AmazonEKSLoadBalancerControllerRole-staging \
  --attach-policy-arn=arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess \
  --approve \

helm install aws-load-balancer-controller-staging eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=ecommerce-platform-staging-eks \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller-staging

# Deploy microservices with staging values
for service in product-catalog user-accounts shopping-cart order-management payment-processing; do
  helm install $service ./helm-charts/$service \
    --namespace staging \
    --values helm-charts/$service/values-staging.yaml
done

# Deploy monitoring stack for staging
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl create configmap prometheus-config-staging \
  --from-file=prometheus.yml=monitoring/environments/prometheus-staging.yml \
  -n monitoring \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f monitoring/grafana/config-staging.yaml
kubectl apply -f monitoring/prometheus/deployment-staging.yaml
kubectl apply -f monitoring/grafana/deployment-staging.yaml
kubectl create secret generic grafana-admin-secret \
  --from-literal=password=admin123 \
  -n monitoring \
  --dry-run=client -o yaml | kubectl apply -f -
```

## Troubleshooting

### Common Issues

#### 1. Pod Fails to Start

```bash
# Check pod events and status
kubectl describe pod <pod-name> -n <namespace>

# Check application logs
kubectl logs <pod-name> -n <namespace>

# For multi-container pods, specify container name
kubectl logs <pod-name> -c <container-name> -n <namespace>

# Check previous container logs if pod restarted
kubectl logs <pod-name> -n <namespace> --previous
```

#### 2. Ingress Not Working

```bash
# Check ALB controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Check ingress status and events
kubectl describe ingress -n <namespace>
kubectl get ingress -n <namespace> -o yaml

# Verify ALB controller service account permissions
kubectl describe serviceaccount aws-load-balancer-controller -n kube-system
```

#### 3. Authentication Issues

```bash
# Update kubeconfig for your specific environment
# For production:
aws eks update-kubeconfig --region us-west-2 --name ecommerce-platform-prod-eks

# For staging:
aws eks update-kubeconfig --region us-west-2 --name ecommerce-platform-staging-eks

# For development (get actual cluster name):
cd terraform/environments/dev
aws eks update-kubeconfig --region us-west-2 --name $(terraform output -raw cluster_name)

# Verify AWS credentials and permissions
aws sts get-caller-identity
aws eks describe-cluster --name <cluster-name> --region us-west-2
```

#### 4. Monitoring Issues

```bash
# Check monitoring pod status
kubectl get pods -n monitoring
kubectl describe pod <prometheus-pod-name> -n monitoring

# Verify ConfigMaps are created properly
kubectl get configmaps -n monitoring
kubectl describe configmap prometheus-config-<env> -n monitoring

# Check persistent volume claims
kubectl get pvc -n monitoring
kubectl describe pvc <pvc-name> -n monitoring

# Test Prometheus targets
kubectl port-forward svc/prometheus-<env> -n monitoring 9090:9090
# Visit http://localhost:9090/targets
```

#### 5. Helm Deployment Issues

```bash
# List Helm releases
helm list -A

# Check Helm release status
helm status <release-name> -n <namespace>

# View Helm release history
helm history <release-name> -n <namespace>

# Debug Helm template rendering
helm template <release-name> ./helm-charts/<chart-name> \
  --values helm-charts/<chart-name>/values-<env>.yaml \
  --debug
```

## Maintenance

### Regular Tasks

1. **Update Node Groups**: Regularly update EKS node group AMIs
2. **Certificate Renewal**: Monitor SSL certificate expiration
3. **Security Patches**: Apply security updates to containers
4. **Backup Verification**: Ensure backup processes are working
5. **Cost Optimization**: Review and optimize resource usage

### Monitoring

- Check Grafana dashboards daily
- Review CloudWatch logs for errors
- Monitor resource utilization trends
- Verify autoscaling behavior

## Next Steps

### Immediate Post-Deployment Tasks

1. **Configure Monitoring Dashboards**: Import pre-built dashboards into Grafana for each microservice
2. **Set Up Alerting Rules**: Configure Prometheus alerting rules for critical metrics and SLOs
3. **Implement Backup Procedures**: Set up backup strategies for persistent volumes and configurations
4. **Security Hardening**: Review and implement additional security policies and network restrictions

### Medium-Term Improvements

5. **CI/CD Pipeline Integration**: Set up automated deployments using GitHub Actions with the branch strategy
6. **Log Aggregation**: Implement centralized logging with ELK stack or CloudWatch Logs Insights
7. **Performance Testing**: Establish load testing procedures for each environment
8. **Disaster Recovery**: Document and test disaster recovery procedures

### Long-Term Operations

9. **Cost Optimization**: Implement cost monitoring and optimization strategies
10. **Compliance Monitoring**: Set up security scanning and compliance monitoring tools
11. **Multi-Region Setup**: Consider multi-region deployment for production resilience
12. **Advanced Monitoring**: Implement distributed tracing and advanced observability tools

## Additional Resources

- **[Monitoring Configuration Summary](monitoring-configuration-summary.md)**: Detailed monitoring setup guide
- **[Multi-Branch Deployment Strategy](multi-branch-deployment-strategy.md)**: Complete CI/CD automation guide
- **[Project Summary](project-summary.md)**: Architecture overview and design decisions
- **[Main README](../README.md)**: Project overview and getting started guide

## Quick Reference Commands

```bash
# Get cluster information
kubectl cluster-info
kubectl get nodes -o wide

# Monitor resource usage
kubectl top nodes
kubectl top pods -A

# Check all deployments across namespaces
kubectl get deployments -A
kubectl get services -A
kubectl get ingress -A

# Monitor logs in real-time
kubectl logs -f deployment/<deployment-name> -n <namespace>

# Port forward for local development
kubectl port-forward svc/<service-name> <local-port>:<service-port> -n <namespace>
```

> **💡 Pro Tip**: Bookmark the monitoring URLs and set up browser shortcuts for quick access to Grafana dashboards and Prometheus metrics.
