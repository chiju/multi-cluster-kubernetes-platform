# Multi-Cluster Kubernetes Platform - Setup Guide

## Step-by-Step Setup Commands

### 1. Create Project Directory
```bash
mkdir -p /Users/c.chandran/2026/labs
cd /Users/c.chandran/2026/labs
mkdir multi-cluster-kubernetes-platform
cd multi-cluster-kubernetes-platform
```

### 2. Initialize Git Repository
```bash
git init
```

### 3. Create GitHub Repository
```bash
gh repo create multi-cluster-kubernetes-platform --public --description "Enterprise multi-cluster Kubernetes platform for learning and interviews" --clone=false
```
**Output:** https://github.com/chiju/multi-cluster-kubernetes-platform

### 4. Add Remote Origin
```bash
git remote add origin https://github.com/chiju/multi-cluster-kubernetes-platform.git
```

### 5. Create Directory Structure
```bash
mkdir -p {docs,infrastructure-catalog/{modules,units},infrastructure-live/aws/dev/eu-central-1,gitops-config/{clusters,infrastructure,workloads},scripts}
```

### 6. Create Setup Directory
```bash
mkdir setup
```

### 7. Initial Commit and Push
```bash
git add .
git commit -m "Initial project structure and README"
git push -u origin main
```

## Directory Structure Created

```
multi-cluster-kubernetes-platform/
├── README.md
├── setup/                       # Setup documentation and scripts
├── docs/                        # Architecture documentation
├── infrastructure-catalog/      # Reusable Terraform modules
│   ├── modules/                 # Base Terraform modules
│   └── units/                   # Terragrunt units
├── infrastructure-live/         # Live environment configurations
│   └── aws/
│       └── dev/
│           └── eu-central-1/
├── gitops-config/              # GitOps configurations
│   ├── clusters/               # Cluster-specific configs
│   ├── infrastructure/         # Infrastructure applications
│   └── workloads/              # Application workloads
└── scripts/                    # Automation scripts
```

## Repository Information

- **GitHub URL:** https://github.com/chiju/multi-cluster-kubernetes-platform
- **Local Path:** /Users/c.chandran/2026/labs/multi-cluster-kubernetes-platform
- **Branch:** main
- **Initial Commit:** b1d5797

## Next Steps

1. Copy modules from existing aws-fluxcd-terragrunt-stacks
2. Create shared infrastructure configuration
3. Build management cluster setup
4. Add workload cluster configurations
5. Configure GitOps workflows

## Prerequisites

Ensure these tools are installed:
```bash
brew install terraform terragrunt kubectl helm flux gh
```

## Notes

- Repository created on: 2026-01-10
- Purpose: Learning enterprise multi-cluster patterns
- Target: Interview preparation and skill development
