#!/bin/bash

# Setup script for configuring the repository with your GitHub details
set -e

echo "🔧 Goose K8s Demo - Repository Setup"
echo "==================================="

# Function to get GitHub repository information
get_repo_info() {
    if git remote -v | grep -q origin; then
        # Extract owner/repo from git remote URL
        REMOTE_URL=$(git remote get-url origin)
        echo "🔍 Detected git remote: $REMOTE_URL"

        if [[ "$REMOTE_URL" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
            DETECTED_OWNER="${BASH_REMATCH[1]}"
            DETECTED_REPO="${BASH_REMATCH[2]}"
            echo "📋 Detected: $DETECTED_OWNER/$DETECTED_REPO"
            return 0
        fi
    fi
    return 1
}

# Try to detect repository info automatically
if get_repo_info; then
    read -p "🤔 Use detected repository '$DETECTED_OWNER/$DETECTED_REPO'? (Y/n): " use_detected
    if [[ -z "$use_detected" || "$use_detected" =~ ^[Yy] ]]; then
        OWNER="$DETECTED_OWNER"
        REPO="$DETECTED_REPO"
    else
        echo "📝 Please provide repository information manually:"
        read -p "GitHub username/organization: " OWNER
        read -p "Repository name: " REPO
    fi
else
    echo "📝 Please provide your GitHub repository information:"
    read -p "GitHub username/organization: " OWNER
    read -p "Repository name: " REPO
fi

# Validate input
if [[ -z "$OWNER" || -z "$REPO" ]]; then
    echo "❌ Owner and repository name are required!"
    exit 1
fi

echo ""
echo "🔄 Configuring repository for: $OWNER/$REPO"
echo "======================================"

# Files to update
FILES=(
    ".github/cr.yaml"
    "helm/goose-k8s-demo/values.yaml"
    "deploy.sh"
)

# Create backup directory
BACKUP_DIR=".setup-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "💾 Creating backups in $BACKUP_DIR..."

# Backup original files
for file in "${FILES[@]}"; do
    if [[ -f "$file" ]]; then
        cp "$file" "$BACKUP_DIR/"
        echo "   ✅ Backed up: $file"
    fi
done

echo ""
echo "🔧 Updating configuration files..."

# Update .github/cr.yaml
if [[ -f ".github/cr.yaml" ]]; then
    sed -i.bak "s/owner-placeholder/$OWNER/g" .github/cr.yaml
    sed -i.bak "s/repo-placeholder/$REPO/g" .github/cr.yaml
    rm .github/cr.yaml.bak
    echo "   ✅ Updated: .github/cr.yaml"
fi

# Update helm/goose-k8s-demo/values.yaml
if [[ -f "helm/goose-k8s-demo/values.yaml" ]]; then
    sed -i.bak "s|ghcr.io/owner-placeholder/repo-placeholder|ghcr.io/$OWNER/$REPO|g" helm/goose-k8s-demo/values.yaml
    rm helm/goose-k8s-demo/values.yaml.bak
    echo "   ✅ Updated: helm/goose-k8s-demo/values.yaml"
fi

# Update deploy.sh
if [[ -f "deploy.sh" ]]; then
    sed -i.bak "s|ghcr.io/owner-placeholder/repo-placeholder|ghcr.io/$OWNER/$REPO|g" deploy.sh
    rm deploy.sh.bak
    echo "   ✅ Updated: deploy.sh"
fi

echo ""
echo "🔍 Configuration Summary:"
echo "========================"
echo "📦 Container Image: ghcr.io/$OWNER/$REPO"
echo "⚓ Helm Repository: https://$OWNER.github.io/$REPO"
echo "🏷️  Repository: $OWNER/$REPO"

echo ""
echo "✅ Repository configuration completed!"
echo ""
echo "📋 Next Steps:"
echo "1. Commit the changes:"
echo "   git add ."
echo "   git commit -m 'Configure repository for $OWNER/$REPO'"
echo "   git push origin main"
echo ""
echo "2. Enable GitHub Actions and Pages in repository settings"
echo "3. Create a release tag to trigger the CI/CD pipeline:"
echo "   git tag v0.1.0"
echo "   git push origin v0.1.0"
echo ""
echo "4. Check the Actions tab to monitor workflow progress"
echo ""
echo "🔄 To restore original configuration, use files in: $BACKUP_DIR"
