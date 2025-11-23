# 🚀 GitHub Actions Workflow

## Overview

The K8s Chat project uses a simplified GitHub Actions workflow focused solely on building and pushing Docker images to Docker Hub. This mirrors the approach used in pods-visualizer demos.

## Workflows

### 1. Build and Push to Docker Hub (`.github/workflows/ci-cd.yml`)

**Purpose**: Automatically build and push Docker images to Docker Hub on every push to main/develop branches.

**Triggers**:
- Push to `main` or `develop` branches
- Push tags with format `v*` (e.g., `v1.0.0`)
- Pull requests to `main` (build only, no push)

**What it does**:
1. **Builds both components** (backend and frontend) in parallel using a matrix strategy
2. **Multi-platform builds** for AMD64 and ARM64 architectures
3. **Pushes to Docker Hub** with multiple tags:
   - `latest` (for main branch)
   - `branch-name` (for branch pushes)
   - `v1.0.0` (for version tags)
   - `main-abc123` (branch + commit hash)

**Required Secrets**:
- `DOCKERHUB_USERNAME` - Your Docker Hub username
- `DOCKERHUB_TOKEN` - Docker Hub access token (not password!)

### 2. Test Builds (`.github/workflows/docker-test.yml`)

**Purpose**: Weekly testing of Docker builds and configurations.

**Triggers**:
- Manual trigger (`workflow_dispatch`)
- Weekly schedule (Mondays at 6 AM UTC)

**What it does**:
1. Tests that both components can build successfully
2. Validates Docker Compose configurations
3. Runs without pushing images (testing only)

## Setup Instructions

### 1. Create Docker Hub Account
1. Sign up at [hub.docker.com](https://hub.docker.com)
2. Create repositories:
   - `your-username/k8s-chat-backend`
   - `your-username/k8s-chat-frontend`

### 2. Generate Access Token
1. Go to Docker Hub → Account Settings → Security
2. Click "New Access Token"
3. Name it "GitHub Actions"
4. Copy the token (you won't see it again!)

### 3. Configure GitHub Secrets
1. Go to your GitHub repo → Settings → Secrets and Variables → Actions
2. Add these repository secrets:
   - `DOCKERHUB_USERNAME`: Your Docker Hub username
   - `DOCKERHUB_TOKEN`: The access token from step 2

### 4. Update Configuration
1. Edit `docker-env.example`:
   ```bash
   DOCKERHUB_USERNAME=your-actual-username
   ```

2. Update Makefile:
   ```bash
   export DOCKERHUB_USERNAME=your-actual-username
   ```

3. Update Helm values:
   ```yaml
   image:
     backend:
       repository: your-actual-username/k8s-chat-backend
     frontend:
       repository: your-actual-username/k8s-chat-frontend
   ```

## Image Tags

The workflow creates these tags automatically:

| Trigger | Tags Created |
|---------|-------------|
| Push to `main` | `latest`, `main`, `main-abc123` |
| Push to `develop` | `develop`, `develop-abc123` |
| Push tag `v1.0.0` | `v1.0.0`, `v1.0`, `1.0.0`, `1.0` |
| Pull Request | Build only, no tags pushed |

## Manual Usage

You can also build and push manually:

```bash
# Set your Docker Hub username
export DOCKERHUB_USERNAME=your-username

# Build images
make build

# Push to Docker Hub (requires docker login)
make push
```

## Deployment

After images are pushed, deploy with:

```bash
# Deploy latest images
make helm-install

# Deploy specific version
helm install k8s-chat ./helm/k8s-chat \
  --set image.backend.tag=v1.0.0 \
  --set image.frontend.tag=v1.0.0
```

## Monitoring

- Check workflow status in GitHub Actions tab
- View image details at `https://hub.docker.com/r/your-username/k8s-chat-backend`
- Monitor image pulls and usage statistics in Docker Hub

## Security Notes

- **Never commit Docker Hub passwords** - always use access tokens
- **Tokens have scope** - create tokens with minimal required permissions
- **Rotate tokens regularly** - update GitHub secrets when you rotate tokens
- **Private repositories** - Consider using private Docker Hub repos for production

This simple workflow ensures your containers are always up-to-date and available for deployment while maintaining security best practices.
