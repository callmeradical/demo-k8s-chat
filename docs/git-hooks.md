# Git Hooks for Demo K8s Chat

This project includes comprehensive git hooks to ensure code quality and security before commits and pushes.

## Overview

Git hooks are local scripts that run automatically on specific git operations. They help catch issues early and maintain code quality standards.

## Available Hooks

### Pre-commit Hook
Runs fast quality checks before each commit:

- ✅ **Merge conflict markers** - Prevents committing unresolved conflicts
- ✅ **Debug statements** - Warns about console.log, debugger, print(), etc.
- ✅ **Large files** - Blocks files >1MB to prevent repository bloat
- ✅ **Secrets detection** - Scans for potential API keys/passwords
- ✅ **Python syntax** - Validates Python code syntax
- ✅ **Whitespace issues** - Catches trailing spaces, mixed line endings

### Pre-push Hook
Runs comprehensive checks before pushing to remote:

- 🔒 **Backend security scan** - Safety vulnerability scanning
- 🎨 **Frontend linting** - ESLint code quality checks
- ⚙️ **Helm chart validation** - Validates Kubernetes deployment configs
- 🐳 **Docker syntax check** - Validates Dockerfile syntax
- 🔍 **Common issues** - Merge conflicts, large files, TODO markers

## Installation

### For New Repository Clones

```bash
# Run the setup script
./scripts/setup-git-hooks.sh
```

### Manual Installation

The hooks are already installed if you're working on this repository. For new clones:

```bash
# Make hooks executable
chmod +x .git/hooks/pre-commit
chmod +x .git/hooks/pre-push

# Verify installation
ls -la .git/hooks/
```

## Usage

### Normal Workflow
Hooks run automatically:

```bash
git add .
git commit -m "feat: add new feature"  # Pre-commit hook runs
git push origin main                   # Pre-push hook runs
```

### Bypassing Hooks
When necessary (use sparingly):

```bash
git commit --no-verify -m "urgent fix"
git push --no-verify origin main
```

## Tool Requirements

For full functionality, install these tools locally:

### Required Tools
- **Git** - Version control (required)
- **Python3** - Backend security scanning
- **Node.js/npm** - Frontend linting and testing
- **Helm** - Kubernetes chart validation
- **Docker** - Container build validation

### Installation Commands

```bash
# macOS (using Homebrew)
brew install python3 node helm docker

# Ubuntu/Debian
apt-get install python3 nodejs npm helm docker.io

# Python packages
pip3 install safety pytest flake8 black isort
```

### Tool Status Check

```bash
# Run the setup script to see tool availability
./scripts/setup-git-hooks.sh
```

## Hook Behavior

### Blocking vs Warning
- **Blocking Issues** (prevent commit/push):
  - Merge conflict markers
  - Large files (>1MB)
  - Python syntax errors
  - Helm chart validation failures
  - Whitespace issues

- **Warning Issues** (allow but warn):
  - Debug statements
  - Potential secrets
  - Missing tests
  - Security scan failures
  - Linting issues

### Environment Handling
Hooks are designed to be resilient:
- Missing tools result in warnings, not failures
- CI/CD pipeline will catch issues that can't be checked locally
- Hooks focus on fast, local checks

## Customization

### Modifying Hooks
Edit the hook files directly:

```bash
# Edit pre-commit hook
nano .git/hooks/pre-commit

# Edit pre-push hook
nano .git/hooks/pre-push

# Make executable after changes
chmod +x .git/hooks/pre-*
```

### Adding New Checks
Add new checks to the appropriate hook:

```bash
# Example: Add new check to pre-commit
print_status "Running my custom check..."
if my_custom_command; then
    print_success "Custom check passed"
else
    print_error "Custom check failed"
    FAILED=1
fi
```

## Troubleshooting

### Common Issues

1. **Permission Denied**
   ```bash
   chmod +x .git/hooks/pre-*
   ```

2. **Tool Not Found**
   - Install missing tools (see requirements above)
   - Hooks will warn but not fail

3. **Hook Not Running**
   - Verify hooks are executable
   - Check if `--no-verify` was used

4. **Performance Issues**
   - Large repositories may have slower hook execution
   - Consider reducing check scope for performance

### Debugging

```bash
# Test hooks manually
.git/hooks/pre-commit
.git/hooks/pre-push

# View hook output
git commit -v
git push -v
```

## Team Usage

### For New Team Members

1. Clone repository
2. Run `./scripts/setup-git-hooks.sh`
3. Install required tools
4. Make first commit to test

### Best Practices

- Don't bypass hooks unless absolutely necessary
- Address warnings when possible
- Keep hooks up to date
- Report hook issues to the team

### Sharing Hook Updates

Hooks are stored in `.git/hooks/` which is not tracked by git. To share updates:

1. Update the setup script: `scripts/setup-git-hooks.sh`
2. Commit and push the script changes
3. Team members re-run the setup script

## Integration with CI/CD

Hooks complement the CI/CD pipeline:

- **Hooks**: Fast, local checks for immediate feedback
- **CI/CD**: Comprehensive testing, security scanning, and deployment

Both work together to maintain code quality!

## Support

For issues with git hooks:

1. Check the troubleshooting section above
2. Run `./scripts/setup-git-hooks.sh` to verify setup
3. Review hook output for specific error messages
4. Consult with the team if needed

Remember: Hooks are there to help maintain code quality and catch issues early! 🛡️
