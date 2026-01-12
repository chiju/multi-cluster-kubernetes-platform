# Cross-Cluster Authentication with Flux CD and AWS Workload Identity

This document outlines the requirements and configuration for enabling cross-cluster GitOps authentication using Flux CD with AWS workload identity (Pod Identity or IRSA).

## Problem Statement

By default, Flux CD cannot authenticate to remote Kubernetes clusters when using ConfigMap-based kubeconfig authentication with AWS workload identity. This results in the error:

```
failed to get access token for cluster: ObjectLevelWorkloadIdentity feature gate is not enabled
```

## Solution Overview

Enable the `ObjectLevelWorkloadIdentity` feature gate in the kustomize-controller to support workload identity authentication for cross-cluster operations.

## Requirements

### 1. Flux CD Version
- **Minimum**: Flux v2.7.0+
- **Recommended**: Flux v2.7.5 (latest)
- **Component**: kustomize-controller v1.7.3+

### 2. Feature Gate Configuration

Enable the `ObjectLevelWorkloadIdentity` feature gate in kustomize-controller:

```bash
kubectl patch deployment kustomize-controller -n flux-system \
  --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--feature-gates=ObjectLevelWorkloadIdentity=true"}]'
```

### 3. AWS Authentication Setup

#### Option A: Pod Identity (Recommended)

1. **Create Pod Identity Association**:
```bash
aws eks create-pod-identity-association \
  --cluster-name management-cluster \
  --namespace flux-system \
  --service-account kustomize-controller \
  --role-arn arn:aws:iam::ACCOUNT:role/cross-cluster-role
```

2. **Add Service Account Annotation**:
```bash
kubectl annotate serviceaccount kustomize-controller -n flux-system \
  eks.amazonaws.com/role-arn=arn:aws:iam::ACCOUNT:role/cross-cluster-role
```

#### Option B: IRSA (Alternative)

1. **Update IAM Role Trust Policy**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT:oidc-provider/oidc.eks.REGION.amazonaws.com/id/OIDC_ID"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.REGION.amazonaws.com/id/OIDC_ID:sub": "system:serviceaccount:flux-system:kustomize-controller",
          "oidc.eks.REGION.amazonaws.com/id/OIDC_ID:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
```

2. **Add Service Account Annotation**:
```bash
kubectl annotate serviceaccount kustomize-controller -n flux-system \
  eks.amazonaws.com/role-arn=arn:aws:iam::ACCOUNT:role/cross-cluster-role
```

### 4. Cross-Cluster IAM Role Configuration

The IAM role must have:

1. **Trust Policy** allowing the service account to assume it
2. **Permissions** to access the target EKS cluster
3. **EKS Access Entry** with appropriate policies

Example IAM permissions:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster"
      ],
      "Resource": "arn:aws:eks:*:ACCOUNT:cluster/*"
    }
  ]
}
```

### 5. ConfigMap Authentication Setup

Create a ConfigMap with the kubeconfig for cross-cluster access:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: workload-cluster-kubeconfig
  namespace: flux-system
data:
  config: |
    apiVersion: v1
    kind: Config
    clusters:
    - cluster:
        server: https://CLUSTER_ENDPOINT
        certificate-authority-data: CERT_DATA
      name: workload-cluster
    contexts:
    - context:
        cluster: workload-cluster
        user: cross-cluster-user
      name: workload-cluster
    current-context: workload-cluster
    users:
    - name: cross-cluster-user
      user:
        exec:
          apiVersion: client.authentication.k8s.io/v1beta1
          command: aws
          args:
          - eks
          - get-token
          - --cluster-name
          - workload-cluster
          - --region
          - REGION
```

### 6. Kustomization Configuration

Reference the ConfigMap in your Kustomization:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: workload-cluster-apps
  namespace: flux-system
spec:
  interval: 10s
  path: "./apps/workload-cluster"
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
  kubeConfig:
    configMapRef:
      name: workload-cluster-kubeconfig
```

## Verification

1. **Check Feature Gate**:
```bash
kubectl get deployment kustomize-controller -n flux-system -o yaml | grep ObjectLevelWorkloadIdentity
```

2. **Verify Authentication**:
```bash
kubectl get kustomization workload-cluster-apps -n flux-system
```

3. **Check Cross-Cluster Resources**:
```bash
kubectl get all -n target-namespace --context workload-cluster
```

## Troubleshooting

### Common Issues

1. **Feature gate not enabled**: Ensure `ObjectLevelWorkloadIdentity=true` is in controller args
2. **Missing service account annotation**: Both Pod Identity and IRSA require the role ARN annotation
3. **IAM permissions**: Verify the role has access to the target EKS cluster
4. **Trust policy**: Ensure the role trusts the correct service account

### Debug Commands

```bash
# Check controller logs
kubectl logs -n flux-system deployment/kustomize-controller

# Verify service account annotations
kubectl get serviceaccount kustomize-controller -n flux-system -o yaml

# Check Pod Identity associations
aws eks list-pod-identity-associations --cluster-name management-cluster
```

## References

- [Flux CD Controller Options](https://fluxcd.io/flux/components/kustomize/options/)
- [AWS EKS Pod Identity](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html)
- [Flux CD Image Repositories with Workload Identity](https://fluxcd.io/flux/components/image/imagerepositories/#serviceaccount-name)
