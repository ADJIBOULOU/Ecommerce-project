# EKS E-commerce Platform 🛒

A comprehensive, production-ready e-commerce platform built on Amazon EKS with microservices architecture, featuring automated deployment pipelines, comprehensive monitoring, and multi-environment support.

## 🏗️ Architecture Overview

This platform implements a cloud-native microservices architecture with:

- **Infrastructure as Code**: Complete AWS EKS infrastructure managed with Terraform
- **Microservices**: Five core services handling different business domains
- **Container Orchestration**: Kubernetes with Helm for application deployment
- **Observability**: Prometheus and Grafana for monitoring and alerting
- **Auto-scaling**: Horizontal Pod Autoscaler and Cluster Autoscaler
- **Load Balancing**: AWS Application Load Balancer with ingress controllers
- **Multi-Environment**: Development, staging, and production environments


## 🚀 Quick Start

### Prerequisites

- AWS CLI v2.0+ configured with appropriate permissions
- Terraform v1.0+
- kubectl v1.29+
- Helm v3.12+
- Docker (for local development)

### 🔧 Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-org/ecommerce-platform.git
   cd ecommerce-platform
   ```

2. **Configure AWS credentials**
   ```bash
   aws configure
   # Ensure your AWS account has EKS, EC2, IAM, and CloudWatch permissions
   ```

3. **Deploy infrastructure** (choose your environment)
   ```bash
   # For development environment
   cd terraform/environments/dev
   terraform init
   terraform plan
   terraform apply
   
   # Get cluster name (dev uses random suffix)
   export CLUSTER_NAME=$(terraform output -raw cluster_name)
   aws eks update-kubeconfig --region us-west-2 --name $CLUSTER_NAME
   ```

4. **Deploy applications**
   ```bash
   # Return to project root
   cd /path/to/ecommerce-platform
   
   # Deploy base Kubernetes resources
   kubectl apply -k kubernetes/environments/dev/
   
   # Deploy monitoring stack
   kubectl create namespace monitoring
   kubectl apply -f monitoring/prometheus/deployment-dev.yaml
   kubectl apply -f monitoring/grafana/deployment-dev.yaml
   
   # Deploy microservices
   helm install product-catalog ./helm-charts/product-catalog \
     --namespace dev \
     --values helm-charts/product-catalog/values-dev.yaml
   ```

5. **Verify deployment**
   ```bash
   kubectl get pods -A
   kubectl get services -n dev
   kubectl port-forward svc/grafana-dev -n monitoring 3000:3000
   ```

> 📖 **For detailed deployment instructions, see [Deployment Guide](docs/deployment-guide.md)**

## 📁 Project Structure

```
ecommerce-platform/
├── 📂 terraform/                    # Infrastructure as Code
│   ├── 📂 environments/            
│   │   ├── 📂 dev/                 # Development environment
│   │   ├── 📂 staging/             # Staging environment
│   │   └── 📂 prod/                # Production environment
│   └── 📂 modules/                 # Reusable Terraform modules
│       ├── 📂 eks/                 # EKS cluster module
│       ├── 📂 iam/                 # IAM roles and policies
│       └── 📂 vpc/                 # VPC and networking
├── 📂 kubernetes/                   # Kubernetes configurations
│   ├── 📂 base/                    # Base configurations
│   └── 📂 environments/            # Environment-specific overlays
├── 📂 helm-charts/                  # Helm charts for microservices
│   ├── 📂 product-catalog/
│   ├── 📂 user-accounts/
│   ├── 📂 shopping-cart/
│   ├── 📂 order-management/
│   └── 📂 payment-processing/
├── 📂 monitoring/                   # Monitoring and observability
│   ├── 📂 environments/            # Environment-specific configs
│   ├── 📂 prometheus/              # Prometheus configurations
│   └── 📂 grafana/                 # Grafana dashboards
├── 📂 .github/                     # GitHub Actions workflows
├── 📂 docs/                        # Documentation
└── 📂 scripts/                     # Utility scripts
```

## 🌍 Multi-Environment Strategy

The platform supports three environments with automated deployment pipelines:

### Environment Configuration

| Environment | Branch | Cluster | Resources | Monitoring | Auto-Deploy |
|-------------|--------|---------|-----------|------------|-------------|
| **Development** | `develop` | `ecommerce-platform-dev-eks-*` | Minimal (cost-optimized) | Basic (7d retention) | ✅ |
| **Staging** | `master` | `ecommerce-platform-staging-eks` | Moderate (testing) | Enhanced (14d retention) | ✅ |
| **Production** | `release` | `ecommerce-platform-prod-eks` | High availability | Full monitoring (30d retention) | ✅ (with approval) |

### Key Differences by Environment

#### Development Environment
- **Purpose**: Feature development and testing
- **Resources**: t3.medium/large instances (Spot instances for cost savings)
- **Monitoring**: 200m CPU, 1Gi memory, 30s scrape intervals
- **Features**: Basic monitoring, single NAT gateway, 7-day log retention

#### Staging Environment
- **Purpose**: Integration testing and performance validation
- **Resources**: m5.large/xlarge + c5.large/xlarge instances
- **Monitoring**: 400m CPU, 1.5Gi memory, 15s scrape intervals
- **Features**: Enhanced monitoring, load testing capabilities, 14-day retention

#### Production Environment
- **Purpose**: Live customer-facing services
- **Resources**: m5.large/xlarge + c5.large/xlarge instances with high availability
- **Monitoring**: 800m CPU, 3Gi memory, 10s scrape intervals, 2 replicas
- **Features**: Full monitoring, multi-AZ NAT gateways, 30-day retention, VPC flow logs

## 🔍 Monitoring & Observability

### Prometheus Metrics Collection

- **Infrastructure Metrics**: Node resource utilization, cluster health
- **Application Metrics**: Custom business metrics from each microservice
- **Kubernetes Metrics**: Pod performance, deployment status, autoscaling events
- **Business Metrics**: Order volumes, payment success rates, user activity

### Grafana Dashboards

- **Infrastructure Overview**: Cluster resource utilization and health
- **Application Performance**: Service-level metrics and SLIs
- **Business Intelligence**: Revenue tracking, conversion funnels
- **Alerting**: Critical system and business threshold violations

### Service Monitoring Coverage

| Service | Health Endpoint | Custom Metrics | Business KPIs |
|---------|----------------|----------------|---------------|
| Product Catalog | `/actuator/health` | Search performance, cache hits | Product views, search queries |
| User Accounts | `/health` | Authentication success rate | User registrations, logins |
| Shopping Cart | `/health` | Cart operations latency | Cart abandonment, conversion |
| Order Management | `/actuator/health` | Order processing time | Order completion rate, revenue |
| Payment Processing | `/health` | Payment gateway latency | Transaction success, fraud detection |

## 🛡️ Security & Compliance

### Security Features

- **Network Security**: VPC with private subnets, security groups, NACLs
- **Authentication**: IAM roles with least privilege access
- **Secrets Management**: Kubernetes secrets for sensitive data
- **Container Security**: Non-root containers, read-only filesystems
- **Network Policies**: Microsegmentation between services

### Compliance & Best Practices

- **Infrastructure as Code**: All resources defined and versioned
- **Immutable Infrastructure**: Container-based deployments
- **Audit Logging**: CloudWatch logs for all activities
- **Backup Strategy**: Persistent volume backups and disaster recovery
- **Security Scanning**: Container vulnerability scanning (recommended)

## 🔄 CI/CD Pipeline

### GitHub Actions Workflows

The platform includes automated deployment pipelines triggered by branch pushes:

- **Development**: Push to `develop` → Deploy to dev environment
- **Staging**: Push to `master` → Deploy to staging environment  
- **Production**: Push to `release` → Deploy to production (with manual approval)

### Pipeline Features

- **Infrastructure Validation**: Terraform plan and validation
- **Container Building**: Docker image building and scanning
- **Application Deployment**: Helm chart deployment with environment-specific values
- **Health Checks**: Post-deployment verification and smoke tests
- **Rollback Capability**: Automated rollback on deployment failures

## 📈 Scaling & Performance

### Auto-Scaling Configuration

- **Horizontal Pod Autoscaler (HPA)**: CPU and memory-based scaling for all microservices
- **Cluster Autoscaler**: Automatic node scaling based on pod scheduling needs
- **Load Balancing**: AWS Application Load Balancer with health checks

### Performance Optimizations

- **Resource Requests/Limits**: Right-sized containers for optimal performance
- **Persistent Volumes**: High-performance EBS volumes for databases
- **Caching Strategy**: Redis for session management and application caching
- **CDN Integration**: CloudFront for static asset delivery (recommended)

## 🛠️ Development Workflow

### Local Development

1. **Set up development environment**
   ```bash
   # Deploy development infrastructure
   cd terraform/environments/dev
   terraform apply
   ```

2. **Connect to development cluster**
   ```bash
   aws eks update-kubeconfig --name $(terraform output -raw cluster_name)
   ```

3. **Deploy and test changes**
   ```bash
   helm upgrade product-catalog ./helm-charts/product-catalog \
     --namespace dev \
     --values helm-charts/product-catalog/values-dev.yaml
   ```

### Testing Strategy

- **Unit Tests**: Individual service testing with mocked dependencies
- **Integration Tests**: Service-to-service communication validation
- **Load Testing**: Performance testing in staging environment
- **End-to-End Tests**: Full user journey validation

## 📚 Documentation

- **[Deployment Guide](docs/deployment-guide.md)**: Step-by-step deployment instructions
- **[Monitoring Configuration](docs/monitoring-configuration-summary.md)**: Comprehensive monitoring setup
- **Architecture Decision Records**: Design decisions and rationale (recommended)
- **API Documentation**: Service API specifications (recommended)


1. **Fork the repository** and create a feature branch
2. **Follow naming conventions** for branches: `feature/description`, `fix/issue-number`
3. **Test changes** in development environment before submitting
4. **Update documentation** for any architectural changes
5. **Submit pull request** with detailed description

### Development Standards

- **Infrastructure**: Follow Terraform best practices and module conventions
- **Kubernetes**: Use resource quotas, limits, and security contexts
- **Monitoring**: Include health checks and custom metrics for new services
- **Documentation**: Update relevant docs with any changes


### Getting Help

- **Issues**: Report bugs and feature requests via GitHub Issues
- **Documentation**: Check the `docs/` directory for detailed guides
- **Monitoring**: Use Grafana dashboards for operational insights

### Maintenance Tasks

- **Regular Updates**: Keep Terraform, Kubernetes, and Helm charts updated
- **Security Patches**: Apply security updates for base images and dependencies
- **Cost Optimization**: Review and optimize resource usage monthly
- **Backup Verification**: Test backup and restore procedures quarterly

## 📋 Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| **Pod CrashLoopBackOff** | Check resource limits and application logs |
| **Ingress not accessible** | Verify ALB controller and security groups |
| **High memory usage** | Review resource requests and JVM settings |
| **Cluster autoscaler not scaling** | Check IAM permissions and node group configuration |

### Useful Commands

```bash
# Check cluster status
kubectl cluster-info
kubectl get nodes -o wide

# Monitor applications
kubectl get pods -A
kubectl top nodes
kubectl top pods -A

# Debug issues
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous

# Access monitoring
kubectl port-forward svc/grafana-dev -n monitoring 3000:3000
kubectl port-forward svc/prometheus-dev -n monitoring 9090:9090
```


**Ready to deploy your e-commerce platform?** Start with the [Deployment Guide](docs/deployment-guide.md) and join the cloud-native revolution! 🚀# Project-EKS
