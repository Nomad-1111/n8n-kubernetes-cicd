# Let's Encrypt Setup Guide for Production

## Overview

This guide explains how to switch from self-signed certificates to Let's Encrypt for production environments. Let's Encrypt provides free, trusted SSL/TLS certificates that are automatically recognized by browsers (no security warnings).

## Prerequisites

Before setting up Let's Encrypt, ensure you have:

1. **Real Domain Name**: You need a publicly accessible domain
   - Example: `n8n.yourdomain.com`
   - Must be able to create DNS records
   - Cannot use `.local` hostnames (e.g., `n8n-dev.local`)

2. **DNS Configuration**: Domain must point to your cluster
   - For cloud Kubernetes: Point DNS A record to LoadBalancer IP
   - For local (Minikube): Use a tunnel service (ngrok, Cloudflare Tunnel) or public IP
   - DNS must be publicly resolvable

3. **Public Accessibility**: Let's Encrypt must reach your cluster
   - HTTP-01 challenge requires port 80 to be publicly accessible
   - Your ingress controller must be reachable from the internet
   - Firewall must allow inbound traffic on port 80

4. **cert-manager Installed**: Run `.\scripts\setup-https.ps1` first if not already done

## Step-by-Step Setup

### Step 1: Install Let's Encrypt Issuer

Run the setup script to create Let's Encrypt ClusterIssuer:

```powershell
# For testing (staging environment - no rate limits, but shows warnings)
.\scripts\setup-letsencrypt.ps1 -Email "your-email@example.com" -Environment "staging"

# For production (real certificates, but has rate limits)
.\scripts\setup-letsencrypt.ps1 -Email "your-email@example.com" -Environment "prod"
```

**Recommendation**: Start with staging to test, then switch to production.

**What this does**:
- Creates `letsencrypt-staging` or `letsencrypt-prod` ClusterIssuer
- Configures HTTP-01 challenge with NGINX ingress
- Sets up automatic certificate renewal

### Step 2: Configure DNS

Point your domain to your ingress controller's public IP:

```powershell
# Get your ingress controller IP
kubectl get svc -n ingress-nginx ingress-nginx-controller

# For LoadBalancer type, use the EXTERNAL-IP
# For NodePort, you'll need the node's public IP
```

**Create DNS A record**:
- **Name**: `n8n` (or your subdomain)
- **Type**: `A`
- **Value**: `<INGRESS_CONTROLLER_IP>`
- **TTL**: 300 (or default)

**Verify DNS**:
```powershell
# Wait a few minutes for DNS propagation, then verify:
nslookup n8n.yourdomain.com
# Should return your ingress controller IP
```

### Step 3: Update Production Values

Edit `helm/values-prod.yaml`:

1. **Update the domain**:
   ```yaml
   ingress:
     host: n8n.yourdomain.com  # Your real domain (not .local)
   ```

2. **Switch to Let's Encrypt issuer**:
   ```yaml
   tls:
     enabled: true
     secretName: n8n-prod-tls
     issuer:
       name: letsencrypt-prod  # or "letsencrypt-staging" for testing
       kind: ClusterIssuer
   ```

3. **Comment out self-signed issuer** (if present):
   ```yaml
   # issuer:
   #   name: selfsigned-issuer
   #   kind: ClusterIssuer
   ```

### Step 4: Deploy and Verify

Argo CD will automatically sync the changes. Monitor the certificate creation:

```powershell
# Watch certificate status
kubectl get certificates -n n8n-prod -w

# Check certificate details
kubectl describe certificate n8n-prod-tls -n n8n-prod

# Verify certificate request
kubectl get certificaterequests -n n8n-prod
```

**Expected timeline**:
- Certificate request created: ~10 seconds
- Let's Encrypt validation: ~1-2 minutes
- Certificate issued: ~2-3 minutes total

### Step 5: Test Access

Once the certificate is ready:

```powershell
# Check ingress shows port 443
kubectl get ingress -n n8n-prod

# Access via HTTPS (no browser warnings!)
# https://n8n.yourdomain.com
```

## Staging vs Production

### Let's Encrypt Staging

- **Use for**: Testing and development
- **Rate limits**: None (unlimited certificates)
- **Browser warnings**: Yes (certificates are not trusted)
- **Issuer name**: `letsencrypt-staging`

**When to use**: Test your setup before switching to production

### Let's Encrypt Production

- **Use for**: Real production deployments
- **Rate limits**: 50 certificates per week per registered domain
- **Browser warnings**: No (fully trusted certificates)
- **Issuer name**: `letsencrypt-prod`

**When to use**: After testing with staging, for actual production

## Troubleshooting

### Certificate Not Issued

**Check certificate status**:
```powershell
kubectl describe certificate n8n-prod-tls -n n8n-prod
```

Look for error messages in the Events section.

**Check certificate requests**:
```powershell
kubectl get certificaterequests -n n8n-prod
kubectl describe certificaterequest <name> -n n8n-prod
```

**Check challenges**:
```powershell
kubectl get challenges -n n8n-prod
kubectl describe challenge <name> -n n8n-prod
```

### Common Issues

#### 1. DNS Not Resolving

**Problem**: Let's Encrypt can't verify domain ownership

**Solution**:
```powershell
# Verify DNS
nslookup n8n.yourdomain.com
# Should return your ingress controller IP

# Check DNS propagation (may take up to 48 hours)
# Use online tools: https://www.whatsmydns.net
```

#### 2. Port 80 Not Accessible

**Problem**: HTTP-01 challenge requires port 80 to be publicly accessible

**Solution**:
- Ensure ingress controller is exposed on port 80
- Check firewall rules allow inbound traffic
- Verify LoadBalancer or NodePort is configured correctly

#### 3. Rate Limits Exceeded

**Problem**: Production Let's Encrypt has 50 certs/week limit

**Solution**:
- Use staging for testing
- Wait for rate limit to reset (weekly)
- Use DNS-01 challenge instead (higher limits)

#### 4. Wrong Domain in Certificate

**Problem**: Certificate issued for wrong domain

**Solution**:
- Verify `ingress.host` in values file matches DNS
- Delete old certificate: `kubectl delete certificate n8n-prod-tls -n n8n-prod`
- Let cert-manager recreate it

#### 5. Certificate Renewal Issues

**Problem**: Certificates not renewing automatically

**Solution**:
```powershell
# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager

# Manually trigger renewal (if needed)
kubectl delete certificate n8n-prod-tls -n n8n-prod
# cert-manager will automatically recreate it
```

## Advanced Configuration

### Using DNS-01 Challenge

For environments where HTTP-01 is not possible, use DNS-01 challenge:

1. **Create DNS-01 ClusterIssuer** (requires DNS provider API credentials)
2. **Configure in values file**:
   ```yaml
   tls:
     issuer:
       name: letsencrypt-dns01-prod
       kind: ClusterIssuer
   ```

See [cert-manager DNS-01 documentation](https://cert-manager.io/docs/configuration/acme/dns01/) for details.

### Multiple Domains

To use Let's Encrypt for multiple environments:

1. Create separate ClusterIssuers (or reuse the same one)
2. Update each environment's values file:
   - `helm/values-dev.yaml` → `n8n-dev.yourdomain.com`
   - `helm/values-uat.yaml` → `n8n-uat.yourdomain.com`
   - `helm/values-prod.yaml` → `n8n.yourdomain.com`

## Switching Back to Self-Signed

If you need to switch back to self-signed certificates:

1. **Update values file**:
   ```yaml
   tls:
     issuer:
       name: selfsigned-issuer
       kind: ClusterIssuer
   ```

2. **Delete Let's Encrypt certificate**:
   ```powershell
   kubectl delete certificate n8n-prod-tls -n n8n-prod
   ```

3. **Argo CD will sync and create new self-signed certificate**

## Best Practices

1. **Always test with staging first**: Use `letsencrypt-staging` to verify setup
2. **Monitor certificate expiration**: Let's Encrypt certs expire in 90 days (auto-renewed)
3. **Use proper DNS TTL**: Set reasonable TTL values for faster DNS updates
4. **Keep email updated**: Let's Encrypt sends expiration warnings
5. **Monitor rate limits**: Production has 50 certs/week limit per domain

## Additional Resources

- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [cert-manager Documentation](https://cert-manager.io/docs/)
- [cert-manager ACME HTTP-01](https://cert-manager.io/docs/configuration/acme/http01/)
- [cert-manager Troubleshooting](https://cert-manager.io/docs/troubleshooting/)

## Summary

✅ **Self-signed**: Works for local development, shows browser warnings  
✅ **Let's Encrypt Staging**: Good for testing, no rate limits, shows warnings  
✅ **Let's Encrypt Production**: Best for production, trusted certificates, rate limits apply

Choose the option that best fits your environment and requirements.

