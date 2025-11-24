#!/bin/bash
#
# Update git hooks to match the streamlined Goose K8s Chat architecture
# This script updates the git hooks to work with our new structure
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}==> ${NC}$1"
}

print_success() {
    echo -e "${GREEN}✅ ${NC}$1"
}

print_warning() {
    echo -e "${YELLOW}⚠️  ${NC}$1"
}

print_error() {
    echo -e "${RED}❌ ${NC}$1"
}

# Check if we're in the project root
if [ ! -f "README.md" ] || [ ! -d ".git" ]; then
    print_error "Please run this script from the project root directory"
    exit 1
fi

print_status "Updating git hooks for streamlined Goose K8s Chat architecture..."

# Create or update pre-commit hook
print_status "Installing pre-commit hook..."
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/sh
#
# Pre-commit hook for demo-k8s-chat
#
# This hook runs quick quality checks before allowing a commit.
# Focuses on fast checks that can be fixed immediately.
#
# To bypass these checks (use sparingly):
# git commit --no-verify

echo "🔍 Running pre-commit quality checks..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo "${BLUE}==>${NC} $1"
}

print_success() {
    echo "${GREEN}✅${NC} $1"
}

print_warning() {
    echo "${YELLOW}⚠️${NC} $1"
}

print_error() {
    echo "${RED}❌${NC} $1"
}

# Track if any checks fail
FAILED=0

# 1. Check for merge conflict markers in staged files
print_status "Checking for merge conflict markers..."
if git diff --cached --name-only | xargs grep -l "<<<<<<< \|======= \|>>>>>>> " 2>/dev/null; then
    print_error "Merge conflict markers found in staged files"
    FAILED=1
else
    print_success "No merge conflict markers found"
fi

# 2. Check for debug statements in staged files
print_status "Checking for debug statements..."
DEBUG_PATTERNS="console\.log\|debugger\|print(\|pdb\.set_trace\|import pdb"
DEBUG_FILES=$(git diff --cached --name-only | xargs grep -l "$DEBUG_PATTERNS" 2>/dev/null | head -5)
if [ ! -z "$DEBUG_FILES" ]; then
    print_warning "Debug statements found in staged files:"
    echo "$DEBUG_FILES"
    print_warning "Consider removing debug statements before committing"
fi

# 3. Check for large files being added
print_status "Checking for large files..."
LARGE_FILES=$(git diff --cached --name-only | xargs ls -la 2>/dev/null | awk '$5 > 1048576 {print $9 " (" $5 " bytes)"}')
if [ ! -z "$LARGE_FILES" ]; then
    print_error "Large files detected (>1MB) in staged changes:"
    echo "$LARGE_FILES"
    print_error "Consider using Git LFS or excluding these files"
    FAILED=1
fi

# 4. Check for secrets or sensitive information
print_status "Checking for potential secrets..."
SECRET_PATTERNS="password\s*=\|api_key\s*=\|secret\s*=\|token\s*=\|AWS_ACCESS_KEY\|GITHUB_TOKEN"
SECRET_FILES=$(git diff --cached --name-only | xargs grep -l -i "$SECRET_PATTERNS" 2>/dev/null | head -5)
if [ ! -z "$SECRET_FILES" ]; then
    print_warning "Potential secrets found in staged files:"
    echo "$SECRET_FILES"
    print_warning "Please verify no actual secrets are being committed"
fi

# 5. Check Python files for basic syntax
print_status "Checking Python syntax..."
PYTHON_FILES=$(git diff --cached --name-only | grep '\.py$')
if [ ! -z "$PYTHON_FILES" ] && command -v python3 >/dev/null 2>&1; then
    for file in $PYTHON_FILES; do
        if [ -f "$file" ]; then
            python3 -m py_compile "$file" 2>/dev/null
            if [ $? -ne 0 ]; then
                print_error "Python syntax error in $file"
                FAILED=1
            fi
        fi
    done
    if [ $FAILED -eq 0 ]; then
        print_success "Python syntax checks passed"
    fi
else
    if [ -z "$PYTHON_FILES" ]; then
        print_status "No Python files in staged changes"
    else
        print_warning "Python3 not available - syntax check will run in CI"
    fi
fi

# 6. Check for whitespace issues
print_status "Checking for whitespace issues..."
git diff --cached --check 2>/dev/null
if [ $? -ne 0 ]; then
    print_error "Whitespace issues found in staged changes"
    FAILED=1
else
    print_success "No whitespace issues found"
fi

# 7. Check Goose configuration and scripts
print_status "Testing Goose configuration..."
GOOSE_CHANGED=$(git diff --cached --name-only | grep -E "goose-config\.yaml|scripts/.*\.sh$|Dockerfile\.goose")
if [ ! -z "$GOOSE_CHANGED" ]; then
    # Check goose-config.yaml syntax if it exists and changed
    if [ -f "goose-config.yaml" ] && echo "$GOOSE_CHANGED" | grep -q "goose-config.yaml"; then
        if command -v python3 >/dev/null 2>&1; then
            python3 -c "import yaml; yaml.safe_load(open('goose-config.yaml'))" 2>/dev/null
            if [ $? -eq 0 ]; then
                print_success "Goose configuration YAML syntax is valid"
            else
                print_error "Invalid YAML syntax in goose-config.yaml"
                FAILED=1
            fi
        else
            print_warning "Python3/PyYAML not available - YAML validation will run in CI"
        fi
    fi

    # Check shell scripts syntax
    SHELL_SCRIPTS=$(echo "$GOOSE_CHANGED" | grep "scripts/.*\.sh$")
    if [ ! -z "$SHELL_SCRIPTS" ]; then
        for script in $SHELL_SCRIPTS; do
            if [ -f "$script" ]; then
                bash -n "$script" 2>/dev/null
                if [ $? -ne 0 ]; then
                    print_error "Shell script syntax error in $script"
                    FAILED=1
                fi
            fi
        done
        if [ $FAILED -eq 0 ]; then
            print_success "Shell scripts syntax checks passed"
        fi
    fi
else
    print_status "No Goose configuration changes detected"
fi

# 8. Check commit message (if available)
if [ -f ".git/COMMIT_EDITMSG" ]; then
    print_status "Checking commit message format..."
    COMMIT_MSG=$(head -1 .git/COMMIT_EDITMSG)

    # Check if commit message is too short
    if [ ${#COMMIT_MSG} -lt 10 ]; then
        print_warning "Commit message is quite short (${#COMMIT_MSG} chars)"
    fi

    # Check if commit message follows conventional format
    if echo "$COMMIT_MSG" | grep -E "^(feat|fix|docs|style|refactor|test|chore|perf|ci|build)(\(.+\))?: .+" >/dev/null; then
        print_success "Commit message follows conventional format"
    else
        print_warning "Consider using conventional commit format: type(scope): description"
    fi
fi

# Summary
echo ""
if [ $FAILED -eq 1 ]; then
    print_error "Pre-commit checks FAILED! 🚫"
    echo ""
    echo "${RED}Commit blocked due to critical issues.${NC}"
    echo "Please fix the errors above and try again."
    echo ""
    echo "To bypass these checks (not recommended):"
    echo "  git commit --no-verify"
    echo ""
    exit 1
else
    print_success "All pre-commit checks passed! 📝"
    echo ""
fi

exit 0
EOF

chmod +x .git/hooks/pre-commit

# Create or update pre-push hook
print_status "Installing pre-push hook..."
cat > .git/hooks/pre-push << 'EOF'
#!/bin/sh
#
# Pre-push hook for demo-k8s-chat
#
# This hook runs security scans, linting, and basic quality checks
# before allowing a push to proceed.
#
# To bypass these checks (use sparingly):
# git push --no-verify

echo "🔍 Running pre-push quality checks..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo "${BLUE}==>${NC} $1"
}

print_success() {
    echo "${GREEN}✅${NC} $1"
}

print_warning() {
    echo "${YELLOW}⚠️${NC} $1"
}

print_error() {
    echo "${RED}❌${NC} $1"
}

# Track if any checks fail
FAILED=0

print_status "Checking if we're in the right directory..."
if [ ! -f "README.md" ] || [ ! -d ".git" ]; then
    print_error "Not in project root directory"
    exit 1
fi

# 1. Goose Configuration Validation
print_status "Running Goose configuration validation..."
if [ -f "goose-config.yaml" ]; then
    # Validate YAML syntax
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "import yaml; yaml.safe_load(open('goose-config.yaml'))" 2>/dev/null
        if [ $? -eq 0 ]; then
            print_success "Goose configuration YAML is valid"
        else
            print_error "Invalid YAML syntax in goose-config.yaml"
            FAILED=1
        fi
    else
        print_warning "Python3 not available - YAML validation will run in CI"
    fi
else
    print_warning "No goose-config.yaml found"
fi

# 2. Shell Scripts Validation
print_status "Running shell scripts validation..."
SHELL_SCRIPTS=$(find scripts -name "*.sh" 2>/dev/null)
if [ ! -z "$SHELL_SCRIPTS" ]; then
    SCRIPT_FAILED=0
    for script in $SHELL_SCRIPTS; do
        if [ -f "$script" ]; then
            bash -n "$script" 2>/dev/null
            if [ $? -ne 0 ]; then
                print_error "Shell script syntax error in $script"
                SCRIPT_FAILED=1
            fi
        fi
    done

    if [ $SCRIPT_FAILED -eq 0 ]; then
        print_success "All shell scripts passed syntax checks"
    else
        FAILED=1
    fi
else
    print_warning "No shell scripts found in scripts/ directory"
fi

# 3. Helm Chart Validation
print_status "Running Helm chart validation..."
if [ -d "helm/k8s-chat" ] && command -v helm >/dev/null 2>&1; then
    helm lint helm/k8s-chat >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_success "Helm chart validation passed"
    else
        print_error "Helm chart validation failed"
        FAILED=1
    fi
else
    if [ ! -d "helm/k8s-chat" ]; then
        print_warning "Helm chart not found - skipping validation"
    else
        print_warning "Helm not available - chart validation will run in CI"
    fi
fi

# 4. Check for common issues
print_status "Checking for common issues..."

# Check for merge conflict markers
if grep -r "<<<<<<< \|======= \|>>>>>>> " --include="*.py" --include="*.js" --include="*.ts" --include="*.tsx" --include="*.yml" --include="*.yaml" . 2>/dev/null; then
    print_error "Merge conflict markers found in files"
    FAILED=1
else
    print_success "No merge conflict markers found"
fi

# Check for TODO/FIXME markers in new commits
if git diff --cached --name-only | xargs grep -l "TODO\|FIXME" 2>/dev/null | head -5; then
    print_warning "Found TODO/FIXME markers in staged files (consider addressing before push)"
fi

# Check for large files
LARGE_FILES=$(git diff --cached --name-only | xargs ls -la 2>/dev/null | awk '$5 > 1048576 {print $9 " (" $5 " bytes)"}')
if [ ! -z "$LARGE_FILES" ]; then
    print_warning "Large files detected (>1MB):"
    echo "$LARGE_FILES"
fi

# 5. Basic Docker build test (optional, only if Docker is available)
print_status "Checking Docker configuration..."
if [ -f "Dockerfile.goose" ] && command -v docker >/dev/null 2>&1; then
    # Just validate the Dockerfile syntax with a dry run, don't actually build
    docker build --dry-run -f Dockerfile.goose . >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_success "Dockerfile.goose syntax is valid"
    else
        print_warning "Dockerfile.goose syntax issues - will be checked in CI"
        # Don't fail for Docker issues in pre-push hook
    fi
else
    if [ ! -f "Dockerfile.goose" ]; then
        print_warning "No Dockerfile.goose found - skipping Docker build test"
    else
        print_warning "Docker not available - build test will run in CI"
    fi
fi

# Summary
echo ""
if [ $FAILED -eq 1 ]; then
    print_error "Pre-push checks FAILED! 🚫"
    echo ""
    echo "${RED}Push blocked due to critical issues.${NC}"
    echo "Please fix the errors above and try again."
    echo ""
    echo "To bypass these checks (not recommended):"
    echo "  git push --no-verify"
    echo ""
    exit 1
else
    print_success "All critical pre-push checks passed! 🚀"
    echo ""
    echo "${GREEN}Ready to push to remote repository.${NC}"
    echo "Full CI/CD pipeline will run additional checks."
    echo ""
fi

exit 0
EOF

chmod +x .git/hooks/pre-push

print_success "Git hooks have been successfully updated!"
echo ""
print_status "Updated hooks now support:"
echo "  • Goose configuration (goose-config.yaml) validation"
echo "  • Shell scripts syntax checking (scripts/*.sh)"
echo "  • Dockerfile.goose syntax validation"
echo "  • Helm chart validation"
echo "  • General quality checks (whitespace, secrets, etc.)"
echo ""
print_warning "Note: The old frontend/backend checks have been removed"
print_success "Git hooks are now aligned with the streamlined architecture!"
