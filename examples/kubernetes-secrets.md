# Kubernetes Secrets Examples for k8s-chat

## Option 1: Create New Secrets via Helm

Add to your `values.yaml`:

```yaml
secrets:
  additional:
    - name: "database-credentials"
      create: true
      envName: "DATABASE_PASSWORD"
      secretName: "database-credentials"
      secretKey: "password"
      type: "Opaque"
      data:
        password: "my-secret-password"
        username: "my-username"

    - name: "api-tokens"
      create: true
      envName: "THIRD_PARTY_API_KEY"
      secretName: "api-tokens"
      secretKey: "token"
      data:
        token: "secret-api-token-here"
```

## Option 2: Reference Existing Secrets

If you already have secrets in the cluster:

```yaml
secrets:
  additional:
    - envName: "DATABASE_PASSWORD"
      secretName: "postgres-credentials"  # Existing secret
      secretKey: "password"
      optional: false

    - envName: "REDIS_PASSWORD"
      secretName: "redis-auth"  # Existing secret
      secretKey: "password"
      optional: true  # Won't fail if secret doesn't exist
```

## Option 3: Create Secret Manually Then Reference

```bash
# Create the secret manually
kubectl create secret generic my-app-secrets \
  --from-literal=database-url="postgresql://user:pass@host/db" \
  --from-literal=jwt-secret="my-jwt-secret" \
  -n demo

# Then reference in values.yaml
```

```yaml
secrets:
  additional:
    - envName: "DATABASE_URL"
      secretName: "my-app-secrets"
      secretKey: "database-url"

    - envName: "JWT_SECRET"
      secretName: "my-app-secrets"
      secretKey: "jwt-secret"
```

## Option 4: Mount Secrets as Files

You can also mount secrets as files instead of environment variables:

```yaml
# In deployment template (add to volumes section)
volumes:
  - name: secret-files
    secret:
      secretName: my-file-secrets
      items:
      - key: config.json
        path: config.json
      - key: private.key
        path: private.key

# And in volumeMounts section
volumeMounts:
  - name: secret-files
    mountPath: "/etc/secrets"
    readOnly: true
```

## Complete Example

```yaml
# values.yaml
secrets:
  anthropic:
    create: true
    apiKey: "your-anthropic-key"

  additional:
    # Create a new secret for database
    - name: "db-credentials"
      create: true
      envName: "DB_PASSWORD"
      secretName: "db-credentials"
      secretKey: "password"
      data:
        password: "secure-db-password"
        username: "myapp"

    # Reference existing Redis secret
    - envName: "REDIS_PASSWORD"
      secretName: "redis-auth"
      secretKey: "password"
      optional: true

    # Create API key secret
    - name: "external-apis"
      create: true
      envName: "EXTERNAL_API_KEY"
      secretName: "external-apis"
      secretKey: "api-key"
      data:
        api-key: "secret-api-key"
        webhook-secret: "webhook-secret"
```

## Testing Secret References

```bash
# Test with creating a new secret
helm template k8s-chat-demo ./helm/k8s-chat \
  --set secrets.anthropic.apiKey="test-key" \
  --set secrets.additional[0].name="test-secret" \
  --set secrets.additional[0].create=true \
  --set secrets.additional[0].envName="TEST_VAR" \
  --set secrets.additional[0].secretName="test-secret" \
  --set secrets.additional[0].secretKey="test-key" \
  --set secrets.additional[0].data.test-key="test-value"

# Test with referencing existing secret
helm template k8s-chat-demo ./helm/k8s-chat \
  --set secrets.anthropic.apiKey="test-key" \
  --set secrets.additional[0].envName="EXISTING_SECRET" \
  --set secrets.additional[0].secretName="existing-secret" \
  --set secrets.additional[0].secretKey="password" \
  --set secrets.additional[0].optional=true
```
