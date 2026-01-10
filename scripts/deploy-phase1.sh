#!/bin/bash

# Multi-Cluster Kubernetes Platform - Phase 1 Deployment Script
# This script demonstrates the Terragrunt stacks workflow

set -e

echo "🚀 Multi-Cluster Kubernetes Platform - Phase 1 Deployment"
echo "=========================================================="

# Change to the stack directory
cd "$(dirname "$0")/../infrastructure-live/aws/dev/eu-central-1"

echo "📁 Current directory: $(pwd)"
echo ""

# Check if terragrunt is installed
if ! command -v terragrunt &> /dev/null; then
    echo "❌ Terragrunt is not installed. Please install it first:"
    echo "   brew install terragrunt"
    exit 1
fi

echo "✅ Terragrunt found: $(terragrunt --version)"
echo ""

# Generate the stack
echo "🔧 Generating Terragrunt stack..."
terragrunt stack generate

echo ""
echo "📋 Generated stack structure:"
find .terragrunt-stack -name "*.hcl" -o -name "*.tf" | head -20

echo ""
echo "🎯 Next steps:"
echo "1. Review the generated configuration in .terragrunt-stack/"
echo "2. Run 'terragrunt stack run plan' to see what will be created"
echo "3. Run 'terragrunt stack run apply' to deploy the infrastructure"
echo ""
echo "📊 Stack summary:"
echo "- 1 Shared VPC (10.0.0.0/16)"
echo "- 1 Management EKS cluster"
echo "- 2 Workload EKS clusters"
echo "- All in eu-central-1 region"
echo ""
echo "💡 This demonstrates enterprise multi-cluster patterns for interviews!"
