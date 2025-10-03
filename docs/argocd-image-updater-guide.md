# ArgoCD Image Updater Guide

## Overview
ArgoCD Image Updater is now installed and configured in your cluster. It automatically monitors container images and updates ArgoCD applications when new versions are available.

## Configuration Status
✅ **Installed**: ArgoCD Image Updater is running in the `argocd` namespace
✅ **Configured**: Basic configuration with Docker Hub registry support
✅ **Ready**: Can monitor and update applications

## How to Use ArgoCD Image Updater

### 1. Basic Application Annotations

Add these annotations to your ArgoCD Application to enable image updating:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
  annotations:
    # Enable image updater for specific images
    argocd-image-updater.argoproj.io/image-list: |
      my-app=docker.io/your-username/your-image:latest
    # Update strategy (latest, semver, name)
    argocd-image-updater.argoproj.io/my-app.update-strategy: latest
    # Write back method (git or argocd)
    argocd-image-updater.argoproj.io/write-back-method: git
```

### 2. Advanced Configuration

#### Multiple Images
```yaml
annotations:
  argocd-image-updater.argoproj.io/image-list: |
    frontend=docker.io/your-username/frontend:latest
    backend=docker.io/your-username/backend:latest
    database=postgres:13
```

#### Tag Filtering
```yaml
annotations:
  # Allow only semantic version tags
  argocd-image-updater.argoproj.io/frontend.allow-tags: regexp:^v?[0-9]+(\.[0-9]+)*(-[a-zA-Z0-9]+)*$
  # Ignore release candidate tags
  argocd-image-updater.argoproj.io/frontend.ignore-tags: regexp:^.*-rc.*$
  # Match specific pattern
  argocd-image-updater.argoproj.io/frontend.match-tags: regexp:^v[0-9]+\.[0-9]+\.[0-9]+$
```

#### Update Strategies
- `latest`: Always use the latest tag
- `semver`: Use semantic versioning (e.g., v1.2.3)
- `name`: Use alphabetical ordering

### 3. Git Write-Back Configuration

For Git write-back method, configure the repository:

```yaml
annotations:
  argocd-image-updater.argoproj.io/git-repository: https://github.com/your-username/your-repo.git
  argocd-image-updater.argoproj.io/git-branch: main
  argocd-image-updater.argoproj.io/git-path: k8s-manifests
```

### 4. ArgoCD Write-Back Configuration

For ArgoCD write-back method (updates ArgoCD directly):

```yaml
annotations:
  argocd-image-updater.argoproj.io/write-back-method: argocd
  argocd-image-updater.argoproj.io/argocd-image-updater.argoproj.io/argocd-server: argocd-server.argocd.svc.cluster.local:443
```

## Monitoring and Logs

### Check Image Updater Status
```bash
kubectl get pods -n argocd | grep image-updater
kubectl logs -n argocd deployment/argocd-image-updater
```

### Check Configuration
```bash
kubectl get configmap argocd-image-updater-config -n argocd -o yaml
```

### View Application Annotations
```bash
kubectl get application <app-name> -n argocd -o yaml
```

## Example: Update Your Demo App

To enable image updating for your demo app, add these annotations to your ArgoCD Application:

```yaml
metadata:
  annotations:
    argocd-image-updater.argoproj.io/image-list: |
      demo-app=docker.io/aadinnr/demo_devops:backend-v1.0.1
    argocd-image-updater.argoproj.io/demo-app.update-strategy: latest
    argocd-image-updater.argoproj.io/write-back-method: argocd
```

## Troubleshooting

### Common Issues

1. **Image Updater Not Running**
   ```bash
   kubectl describe pod -n argocd -l app.kubernetes.io/name=argocd-image-updater
   ```

2. **Configuration Issues**
   ```bash
   kubectl logs -n argocd deployment/argocd-image-updater
   ```

3. **Permission Issues**
   ```bash
   kubectl get clusterrolebinding argocd-image-updater
   kubectl get rolebinding argocd-image-updater -n argocd
   ```

### Manual Image Update

You can manually trigger an image update:

```bash
kubectl patch application <app-name> -n argocd --type merge -p '{"metadata":{"annotations":{"argocd-image-updater.argoproj.io/image-list":"your-image=docker.io/your-username/your-image:new-tag"}}}'
```

## Next Steps

1. **Add annotations** to your existing ArgoCD applications
2. **Configure Git write-back** if you want to update your Git repository
3. **Set up monitoring** to track image updates
4. **Test with a sample application** to verify functionality

The ArgoCD Image Updater is now ready to automatically keep your container images up to date! 🚀
