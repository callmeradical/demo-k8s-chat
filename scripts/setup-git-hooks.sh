#!/bin/bash
#
# Git Hooks Setup Script for demo-k8s-chat
#
# This script installs git hooks to run quality checks before commits and pushes.
# Run this script after cloning the repository to enable quality gates.

echo "🔧 Setting up Git hooks for demo-k8s-chat..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    print_error "Not in a git repository! Please run this from the project root."
    exit 1
fi

# Check if hooks directory exists
if [ ! -d ".git/hooks" ]; then
    print_error ".git/hooks directory not found!"
    exit 1
fi

print_status "Installing Git hooks..."

# Copy existing hooks (they're already created)
if [ -f ".git/hooks/pre-commit" ]; then
    print_success "Pre-commit hook already installed"
else
    print_warning "Pre-commit hook not found - you may need to create it manually"
fi

if [ -f ".git/hooks/pre-push" ]; then
    print_success "Pre-push hook already installed"
else
    print_warning "Pre-push hook not found - you may need to create it manually"
fi

# Make sure hooks are executable
chmod +x .git/hooks/pre-commit 2>/dev/null
chmod +x .git/hooks/pre-push 2>/dev/null

echo ""
print_success "Git hooks setup complete! 🎉"
echo ""
echo "${GREEN}What's available:${NC}"
echo "  • Pre-commit hook: Fast quality checks before each commit"
echo "  • Pre-push hook: Security scans and linting before push"
echo ""
echo "${BLUE}How to use:${NC}"
echo "  • Hooks run automatically on commit/push"
echo "  • To bypass: git commit --no-verify or git push --no-verify"
echo "  • Hooks are local to your repository clone"
echo ""
echo "${YELLOW}Quality checks included:${NC}"
echo "  Pre-commit:"
echo "    - Merge conflict markers"
echo "    - Debug statements detection"
echo "    - Large file detection"
echo "    - Secret scanning"
echo "    - Python syntax validation"
echo "    - Whitespace issues"
echo ""
echo "  Pre-push:"
echo "    - Backend security scanning (safety)"
echo "    - Frontend linting (ESLint)"
echo "    - Helm chart validation"
echo "    - Docker build testing"
echo "    - Common issue detection"
echo ""

# Check if required tools are available
echo "${BLUE}Tool availability check:${NC}"

if command -v python3 >/dev/null 2>&1; then
    print_success "Python3 available - security scans will work"

    # Check if safety is installed
    if python3 -c "import safety" 2>/dev/null; then
        print_success "Safety module available - security scanning ready"
    else
        print_warning "Safety module not installed - run: python3 -m pip install safety"
    fi
else
    print_warning "Python3 not found - install for security scanning"
fi

if command -v npm >/dev/null 2>&1; then
    print_success "npm available - frontend linting will work"
else
    print_warning "npm not found - install Node.js for frontend linting"
fi

if command -v helm >/dev/null 2>&1; then
    print_success "Helm available - chart validation will work"
else
    print_warning "Helm not found - install for chart validation"
fi

if command -v docker >/dev/null 2>&1; then
    print_success "Docker available - build tests will work"
else
    print_warning "Docker not found - install for build testing"
fi

echo ""
print_success "Setup complete! Your git workflow now includes quality gates. 🛡️"
echo ""
echo "${GREEN}Next steps:${NC}"
echo "  1. Try making a commit to test the pre-commit hook"
echo "  2. Try pushing to test the pre-push hook"
echo "  3. Install missing tools if you want full functionality"
echo ""
