#!/bin/bash
# FluxCD Structure Migration Script
# Migrates from current structure to 2025 best practices

set -e

REPO_ROOT="/Users/c.chandran/2026/labs/multi-cluster-kubernetes-platform"
OLD_CONFIG="flux-config"
NEW_CONFIG="flux-config-new"

echo "🔄 Migrating FluxCD structure to 2025 best practices..."

cd "$REPO_ROOT"

# Backup current structure
echo "📦 Creating backup..."
cp -r "$OLD_CONFIG" "${OLD_CONFIG}-backup-$(date +%Y%m%d-%H%M%S)"

# Replace old structure with new
echo "🔄 Replacing structure..."
mv "$OLD_CONFIG" "${OLD_CONFIG}-old"
mv "$NEW_CONFIG" "$OLD_CONFIG"

echo "✅ Migration complete!"
echo ""
echo "📁 New structure:"
echo "├── apps/"
echo "│   ├── base/           # Base application configurations"
echo "│   └── production/     # Production-specific patches"
echo "├── infrastructure/"
echo "│   ├── controllers/    # Platform controllers (Crossplane, Istio)"
echo "│   └── configs/        # Platform configurations (APIs, Kiali)"
echo "└── clusters/"
echo "    └── management/     # Cluster-specific Flux configurations"
echo ""
echo "🔧 Next steps:"
echo "1. Update cluster bootstrap to point to clusters/management/"
echo "2. Commit and push changes"
echo "3. Verify Flux reconciliation"
