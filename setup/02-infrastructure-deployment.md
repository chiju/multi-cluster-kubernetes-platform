# 02 - Infrastructure Deployment Guide

## Overview
Deploy multi-cluster Kubernetes platform with Flux GitOps using Terragrunt stacks.

**Current Configuration:**
- 1 Shared VPC (10.0.0.0/16) 
- Management Cluster (Flux CD, monitoring, security tools)
- Workload Cluster (applications, testing)
- Secure API access (restricted to your IP)

## Environment Variables Set
```bash
export AWS_PROFILE=dev_6742
export TF_LOG=TRACE
export TF_LOG_PATH=$(pwd)/terragrunt-trace.log
export AWS_ACCOUNT_ID_DEV="123456789012"
export ADMIN_IP="$(curl -s -4 ifconfig.me)/32"
```

## Deployment Commands

### 1. Navigate and Load Environment
```bash
cd /Users/c.chandran/2026/labs/multi-cluster-kubernetes-platform/infrastructure-live/aws/dev
source .env
cd eu-central-1
```

### 2. Generate Stack
```bash
terragrunt stack clean
terragrunt stack generate
```

### 3. Plan Deployment (with backend bootstrap)
```bash
terragrunt stack run plan --backend-bootstrap --non-interactive
```

### 4. Deploy Infrastructure
```bash
terragrunt stack run apply --non-interactive
```

## Post-Deployment Setup

### Configure kubectl Access
```bash
# Management cluster
aws eks update-kubeconfig --region eu-central-1 --name management-cluster --profile dev_6742

# Workload cluster  
aws eks update-kubeconfig --region eu-central-1 --name workload-cluster-1 --profile dev_6742
```

### Verify Clusters
```bash
kubectl get nodes --context arn:aws:eks:eu-central-1:123456789012:cluster/management-cluster
kubectl get nodes --context arn:aws:eks:eu-central-1:123456789012:cluster/workload-cluster-1
```

## Security Features
- API endpoints restricted to your IP only
- KMS encryption for EKS secrets
- CloudWatch logging enabled
- Private subnets for worker nodes
- Public subnets for load balancers only

## Troubleshooting
- Check `terragrunt-trace.log` for detailed Terraform output
- Verify `$ADMIN_IP` is current if access denied
- Use `terragrunt backend bootstrap` if S3 backend issues

## Next Phase
- Install Flux CD on management cluster
- Configure GitOps workflows
- Set up monitoring stack
