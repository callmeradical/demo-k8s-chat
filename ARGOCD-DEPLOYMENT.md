# ArgoCD Deployment Guide for k8s-chat

This guide covers the best practices for securely deploying k8s-chat with ArgoCD.

## 🔐 API Key Management Options

### Option 1: External Secrets Operator (Recommended)

**Prerequisites:**
- External Secrets Operator installed in cluster
- SecretStore configured (Vault, AWS Secrets Manager, etc.)

**Configuration:**
```yaml
# In ArgoCD Application values
secrets:
  anthropic:
    create: true
    external: true
    secretStore: "vault-backend"
    externalKey: "anthropic/api-keys"
    externalProperty: "api-key"
    refreshInterval: "1h"
```

**Benefits:**
- ✅ Secrets never stored in Git
- ✅ Automatic rotation support
- ✅ Centralized secret management
- ✅ Audit trail

### Option 2: Sealed Secrets

**Prerequisites:**
- Sealed Secrets controller installed in cluster

**Steps:**
1. Create the SealedSecret:
```bash
echo -n "your-anthropic-api-key" | kubectl create secret generic k8s-chat-demo-anthropic \
  --dry-run=client --from-file=api-key=/dev/stdin -o yaml | \
  kubeseal -o yaml > sealed-secret.yaml
```

2. Configure Helm chart:
```yaml
# In ArgoCD Application values
secrets:
  anthropic:
    create: false  # SealedSecret will create the secret
```

3. Apply the SealedSecret before or alongside the Application

**Benefits:**
- ✅ Safe to store in Git (encrypted)
- ✅ GitOps friendly
- ✅ No external dependencies

### Option 3: ArgoCD Private Repository (Less Secure)

Store the API key in a private Helm repository or private Git repo:

```yaml
# values-production.yaml (in private repo)
secrets:
  anthropic:
    create: true
    apiKey: "your-actual-api-key-here"
```

**Benefits:**
- ✅ Simple setup
- ❌ API key in plain text (even if private)
- ❌ No rotation mechanism

## 🚀 Deployment Examples

### Using External Secrets
```bash
kubectl apply -f argocd-application.yaml
```

### Using Sealed Secrets
```bash
# 1. Create and apply the sealed secret
kubectl apply -f examples/sealed-secret.yaml

# 2. Deploy with secrets.anthropic.create=false
kubectl apply -f argocd-application.yaml
```

### Using ArgoCD Repository Credentials
```bash
# Store API key in repository and reference in values
argocd app create k8s-chat-demo \
  --repo https://github.com/your-org/k8s-chat-config \
  --path helm-values \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace demo
```

## 🔧 ArgoCD Application Configuration

The provided `argocd-application.yaml` demonstrates:
- Using OCI Helm registry
- External secrets configuration
- Automated sync policies
- Namespace management
- Proper finalizers

## 🛡️ Security Best Practices

1. **Never commit plain-text API keys to Git**
2. **Use External Secrets Operator when possible**
3. **Implement secret rotation policies**
4. **Monitor secret access and usage**
5. **Use ArgoCD RBAC to limit access**
6. **Enable ArgoCD audit logging**

## 📋 Troubleshooting

**External Secret not syncing:**
```bash
kubectl describe externalsecret k8s-chat-demo-anthropic -n demo
kubectl logs -l app.kubernetes.io/name=external-secrets -n external-secrets-system
```

**Sealed Secret issues:**
```bash
kubectl describe sealedsecret k8s-chat-demo-anthropic -n demo
kubectl logs -l app.kubernetes.io/name=sealed-secrets -n kube-system
```

**ArgoCD sync issues:**
```bash
argocd app get k8s-chat-demo
argocd app sync k8s-chat-demo --dry-run
```
