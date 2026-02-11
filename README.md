# Multi-Cluster Kubernetes Platform

multi-cluster Kubernetes platform demonstrating progressive architecture patterns

## 🎯 Learning Objectives

- **Multi-cluster architecture** patterns and best practices
- **Enterprise infrastructure** design with Terragrunt
- **GitOps workflows** across multiple clusters
- **Cross-cluster networking** and service mesh
- **Platform engineering** concepts

## 🏗️ Architecture Phases

### Phase 1: Shared Infrastructure + Multi-Cluster (Same Region)
```
AWS eu-central-1
├── Shared VPC (10.0.0.0/16)
├── Management Cluster (GitOps, Monitoring)
├── Workload Cluster 1 (Applications)
└── Workload Cluster 2 (Applications)
```

### Phase 2: Multi-Region
```
AWS
├── eu-central-1 (Management + Workloads)
└── us-east-1 (Workload clusters)
```

### Phase 3: Multi-Account
```
AWS Organization
├── Management Account (Control plane)
├── Dev Account (Development workloads)
├── Staging Account (Pre-production)
└── Prod Account (Production workloads)
```

### Phase 4: Multi-Cloud
```
Management Cluster (AWS)
├── AWS EKS Workload Clusters
├── GCP GKE Workload Clusters
└── Azure AKS Workload Clusters
```

## 🛠️ Technology Stack

- **Infrastructure**: Terragrunt + Terraform
- **Kubernetes**: EKS, GKE, AKS
- **GitOps**: FluxCD / ArgoCD
- **Service Mesh**: Istio
- **Monitoring**: Prometheus + Grafana
- **Networking**: AWS VPC, GCP VPC, Azure VNet

## 📁 Repository Structure

```
multi-cluster-kubernetes-platform/
├── docs/                        # Architecture documentation
├── infrastructure-catalog/      # Reusable Terraform modules
│   ├── modules/                 # Base Terraform modules
│   └── units/                   # Terragrunt units
├── infrastructure-live/         # Live environment configurations
│   ├── aws/                     # AWS environments
│   ├── gcp/                     # GCP environments (Phase 4)
│   └── azure/                   # Azure environments (Phase 4)
├── gitops-config/              # GitOps configurations
│   ├── clusters/               # Cluster-specific configs
│   ├── infrastructure/         # Infrastructure applications
│   └── workloads/              # Application workloads
└── scripts/                    # Automation scripts
```

## 🚀 Quick Start

### Prerequisites
```bash
# Required tools
brew install terraform terragrunt kubectl helm flux
```

### Phase 1: Multi-Cluster Setup
```bash
# Deploy shared infrastructure
cd infrastructure-live/aws/dev/eu-central-1/shared-infrastructure
terragrunt apply

# Deploy management cluster
cd ../management-cluster
terragrunt apply

# Deploy workload clusters
cd ../workload-cluster-1
terragrunt apply
```

## 📚 Learning Resources

- [Multi-Cluster Architecture Patterns](./docs/multi-cluster-patterns.md)
- [Enterprise GitOps Workflows](./docs/gitops-workflows.md)
- [Cross-Cluster Networking](./docs/networking.md)
- [Platform Engineering Best Practices](./docs/platform-engineering.md)

## 🎤 Interview Talking Points

- **Enterprise architecture** decision making
- **Multi-cluster** vs **multi-tenant** trade-offs
- **GitOps** at scale across clusters
- **Platform engineering** principles
- **Multi-cloud** strategy and implementation

## 📈 Progress Tracking

- [ ] Phase 1: Multi-cluster (same region)
- [ ] Phase 2: Multi-region
- [ ] Phase 3: Multi-account
- [ ] Phase 4: Multi-cloud (AWS + GCP)
- [ ] Phase 5: Three clouds (AWS + GCP + Azure)

---

**Built for learning enterprise Kubernetes patterns and interview preparation.**
