# FluxCD Directory Structure - 2025 Best Practices

This repository follows the FluxCD 2025 best practices for GitOps directory structure.

## Structure Overview

```
flux-config/
├── apps/
│   ├── base/           # Base application configurations
│   └── production/     # Production-specific patches and overrides
├── infrastructure/
│   ├── controllers/    # Platform controllers and base services
│   │   ├── crossplane/ # Crossplane control plane
│   │   ├── istio-base/ # Istio service mesh base
│   │   ├── istiod/     # Istio control plane
│   │   ├── istio-gateway/ # Istio ingress gateway
│   │   └── gateway-api/   # Kubernetes Gateway API
│   └── configs/        # Platform configurations and APIs
│       ├── platform-apis/ # Crossplane XRDs and Compositions
│       └── kiali/         # Service mesh observability
└── clusters/
    └── management/     # Management cluster Flux configuration
        ├── infrastructure.yaml # Infrastructure reconciliation
        ├── apps.yaml          # Applications reconciliation
        └── kustomization.yaml # Cluster root kustomization
```

## Key Principles

### 1. Separation of Concerns
- **Controllers**: Core platform services that provide capabilities
- **Configs**: Configuration and APIs that use the controllers
- **Apps**: Application workloads that consume platform services

### 2. Dependency Management
```yaml
# Infrastructure controllers first
infra-controllers → infra-configs → apps
```

### 3. Environment Patterns
- `base/` contains common configurations
- `production/` contains environment-specific patches
- Use Kustomize overlays for environment differences

## Migration from Previous Structure

The previous structure has been reorganized as follows:

| Old Location | New Location | Purpose |
|--------------|--------------|---------|
| `infrastructure-base/crossplane/` | `infrastructure/controllers/crossplane/` | Core controller |
| `infrastructure-base/istio-base/` | `infrastructure/controllers/istio-base/` | Core controller |
| `infrastructure/istiod/` | `infrastructure/controllers/istiod/` | Core controller |
| `infrastructure/istio-gateway/` | `infrastructure/controllers/istio-gateway/` | Core controller |
| `platform-apis/` | `infrastructure/configs/platform-apis/` | Platform configuration |
| `infrastructure/kiali/` | `infrastructure/configs/kiali/` | Platform configuration |
| `workload-apps/` | `apps/base/` | Application base |

## Bootstrap Configuration

Update your Flux bootstrap to point to the new cluster configuration:

```bash
flux bootstrap github \
  --owner=${GITHUB_USER} \
  --repository=${GITHUB_REPO} \
  --branch=main \
  --path=flux-config/clusters/management \
  --personal
```

## Benefits of This Structure

1. **Scalability**: Easy to add new environments and clusters
2. **Maintainability**: Clear separation reduces configuration drift
3. **Reusability**: Base configurations can be shared across environments
4. **Dependencies**: Explicit ordering prevents race conditions
5. **Standards**: Follows FluxCD community best practices
