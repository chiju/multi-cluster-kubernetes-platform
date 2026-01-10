# Multi-Cluster Kubernetes Platform - Phase 1
# Shared VPC with Management + 1 Workload Cluster in same region
# Management cluster will run Flux for GitOps infrastructure management

unit "shared_vpc" {
  source = "${get_repo_root()}/infrastructure-catalog/units/vpc"
  path   = "vpc"
  
  values = {
    name        = "multi-cluster-vpc"
    environment = "dev"
    cidr_block  = "10.1.0.0/16"
    
    # Public subnets for load balancers
    public_subnet_cidrs = [
      "10.1.1.0/24",   # eu-central-1a
      "10.1.2.0/24",   # eu-central-1b  
      "10.1.3.0/24"    # eu-central-1c
    ]
    
    # Private subnets for general workloads
    private_subnet_cidrs = [
      "10.1.10.0/24",  # eu-central-1a
      "10.1.20.0/24",  # eu-central-1b
      "10.1.30.0/24"   # eu-central-1c
    ]
    
    # Disable database subnets to avoid conflicts
    create_database_subnets = false
    database_subnet_cidrs   = []
    
    enable_nat_gateway = true
    single_nat_gateway = false  # One NAT per AZ for HA
    
    # EKS-specific tags
    public_subnet_tags = {
      "kubernetes.io/role/elb" = "1"
    }
    
    private_subnet_tags = {
      "kubernetes.io/role/internal-elb" = "1"
      "karpenter.sh/discovery" = "multi-cluster-vpc"
    }
    
    tags = {
      Project     = "multi-cluster-k8s-platform"
      Phase       = "1"
      Environment = "dev"
      ManagedBy   = "terragrunt-stacks"
    }
  }
}

unit "fluxcd" {
  source = "${get_repo_root()}/infrastructure-catalog/units/fluxcd"
  path   = "fluxcd"
  
  values = {
    environment = "dev"
    
    # Git repository configuration
    git_repo_url = "https://github.com/chiju/multi-cluster-kubernetes-platform"
    
    # GitHub App authentication
    github_app_id              = get_env("FLUXCD_APP_ID")
    github_app_installation_id = get_env("FLUXCD_APP_INSTALLATION_ID")
    github_app_private_key     = get_env("FLUXCD_APP_PRIVATE_KEY")
    
    tags = {
      Project     = "multi-cluster-k8s-platform"
      Phase       = "1"
      Environment = "dev"
      Component   = "gitops"
      ManagedBy   = "terragrunt-stacks"
    }
  }
}

unit "management_cluster" {
  source = "${get_repo_root()}/infrastructure-catalog/units/eks"
  path   = "management-cluster"
  
  values = {
    cluster_name       = "management-cluster"
    kubernetes_version = "1.34"
    
    # API endpoint access
    endpoint_public_access = true
    public_access_cidrs    = [get_env("ADMIN_IP")]
    
    # Node configuration
    instance_types   = ["t3.medium"]
    desired_capacity = 4
    min_capacity     = 2
    max_capacity     = 6
    
    # Cluster settings
    cluster_log_retention_days = 30
    enable_irsa               = true
    enable_cluster_autoscaler = true
    
    # Access entries
    github_role_arn     = null
    org_access_role_arn = "arn:aws:iam::${get_env("AWS_ACCOUNT_ID_DEV")}:role/OrganizationAccountAccessRole"
    
    tags = {
      Project      = "multi-cluster-k8s-platform"
      Phase        = "1"
      Environment  = "dev"
      ClusterType  = "management"
      ManagedBy    = "terragrunt-stacks"
    }
  }
}

unit "workload_cluster_1" {
  source = "${get_repo_root()}/infrastructure-catalog/units/eks"
  path   = "workload-cluster-1"
  
  values = {
    cluster_name       = "workload-cluster-1"
    kubernetes_version = "1.34"
    
    # API endpoint access
    endpoint_public_access = true
    public_access_cidrs    = [get_env("ADMIN_IP")]
    
    # Node configuration
    instance_types   = ["t3.medium"]
    desired_capacity = 2
    min_capacity     = 1
    max_capacity     = 5
    
    # Cluster settings
    cluster_log_retention_days = 30
    enable_irsa               = true
    enable_cluster_autoscaler = true
    
    # Access entries
    github_role_arn     = null
    org_access_role_arn = "arn:aws:iam::${get_env("AWS_ACCOUNT_ID_DEV")}:role/OrganizationAccountAccessRole"
    
    tags = {
      Project      = "multi-cluster-k8s-platform"
      Phase        = "1"
      Environment  = "dev"
      ClusterType  = "workload"
      ManagedBy    = "terragrunt-stacks"
    }
  }
}

# unit "workload_cluster_2" {
#   source = "${get_repo_root()}/infrastructure-catalog/units/eks"
#   path   = "workload-cluster-2"
#   
#   values = {
#     cluster_name       = "workload-cluster-2"
#     kubernetes_version = "1.28"
#     
#     # API endpoint access
#     endpoint_public_access = true
#     public_access_cidrs    = [get_env("ADMIN_IP")]
#     
#     # Node configuration
#     instance_types   = ["t3.medium"]
#     desired_capacity = 2
#     min_capacity     = 1
#     max_capacity     = 5
#     
#     # Cluster settings
#     cluster_log_retention_days = 30
#     enable_irsa               = true
#     enable_cluster_autoscaler = true
#     
#     # Access entries (to be configured later)
#     github_role_arn     = ""
#     org_access_role_arn = ""
#     
#     tags = {
#       Project      = "multi-cluster-k8s-platform"
#       Phase        = "1"
#       Environment  = "dev"
#       ClusterType  = "workload"
#       ManagedBy    = "terragrunt-stacks"
#     }
#   }
# }
