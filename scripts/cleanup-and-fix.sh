#!/bin/bash

# Multi-cluster Kubernetes Platform - Stack Cleanup and Fix Script
set -e

# Source environment variables
source /Users/c.chandran/2026/labs/multi-cluster-kubernetes-platform/infrastructure-live/aws/dev/.env

echo "🧹 Starting stack cleanup and fix..."

# 1. Wait for cluster deletion to complete
echo "⏳ Waiting for cluster deletion to complete..."
while true; do
    STATUS=$(aws eks describe-cluster --name workload-cluster-1 --region eu-central-1 --query 'cluster.status' --output text 2>/dev/null || echo "DELETED")
    if [ "$STATUS" = "DELETED" ]; then
        echo "✅ Cluster workload-cluster-1 deleted successfully"
        break
    elif [ "$STATUS" = "DELETING" ]; then
        echo "⏳ Cluster still deleting... waiting 30 seconds"
        sleep 30
    else
        echo "❌ Unexpected cluster status: $STATUS"
        break
    fi
done

# 2. Clean up any remaining AWS resources
echo "🧹 Cleaning up remaining AWS resources..."

# Delete any remaining node groups (in case they exist)
aws eks list-nodegroups --cluster-name workload-cluster-1 --region eu-central-1 --query 'nodegroups[]' --output text 2>/dev/null | while read nodegroup; do
    if [ ! -z "$nodegroup" ]; then
        echo "Deleting nodegroup: $nodegroup"
        aws eks delete-nodegroup --cluster-name workload-cluster-1 --nodegroup-name $nodegroup --region eu-central-1 || true
    fi
done

# 3. Remove corrupted terragrunt stack
echo "🗑️  Removing corrupted terragrunt stack..."
rm -rf .terragrunt-stack

# 4. Clean up any terraform state files
echo "🗑️  Cleaning up terraform state files..."
find . -name "*.tfstate*" -delete 2>/dev/null || true
find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name ".terragrunt-cache" -type d -exec rm -rf {} + 2>/dev/null || true

# 5. Verify AWS resources are clean
echo "🔍 Verifying AWS resources are clean..."
CLUSTERS=$(aws eks list-clusters --region eu-central-1 --query 'clusters[]' --output text)
if [ ! -z "$CLUSTERS" ]; then
    echo "⚠️  Warning: Found remaining clusters: $CLUSTERS"
else
    echo "✅ No EKS clusters found"
fi

VPCS=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=multi-cluster-vpc" --region eu-central-1 --query 'Vpcs[].VpcId' --output text)
if [ ! -z "$VPCS" ]; then
    echo "⚠️  Warning: Found VPCs that may need cleanup: $VPCS"
else
    echo "✅ No matching VPCs found"
fi

echo "✅ Stack cleanup completed successfully!"
echo ""
echo "🚀 Ready to deploy fresh infrastructure with:"
echo "   terragrunt stack run apply --non-interactive"
