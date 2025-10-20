# Jenkins Helm Chart with Docker-in-Docker

This Helm chart deploys Jenkins CI/CD with Docker-in-Docker (DinD) capabilities for building container images.

## Features

- **Jenkins LTS** with JDK 17
- **Docker-in-Docker** for secure container building
- **GitHub Integration** with webhooks and OAuth
- **Kubernetes Integration** with RBAC permissions
- **Persistent Storage** for Jenkins data
- **Ingress Support** for external access
- **Pre-configured Plugins** for CI/CD workflows

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- Nginx Ingress Controller (optional)

## Installation

1. **Add the chart repository** (if using a remote repository):
   ```bash
   helm repo add jenkins https://charts.jenkins.io
   helm repo update
   ```

2. **Install Jenkins**:
   ```bash
   helm install jenkins ./jenkins -n jenkins --create-namespace
   ```

3. **Or install with custom values**:
   ```bash
   helm install jenkins ./jenkins -n jenkins --create-namespace -f custom-values.yaml
   ```

## Configuration

### Key Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `jenkins.adminUser` | Jenkins admin username | `admin` |
| `jenkins.adminPassword` | Jenkins admin password | `admin123` |
| `docker.enabled` | Enable Docker-in-Docker | `true` |
| `persistence.enabled` | Enable persistent storage | `true` |
| `persistence.size` | Storage size | `20Gi` |
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.hosts[0].host` | Ingress hostname | `jenkins.local` |

### Docker Configuration

The chart includes a Docker-in-Docker setup that provides:
- Isolated Docker daemon for builds
- No host socket access required
- Secure container building environment
- Registry authentication support

### GitHub Integration

Pre-configured with GitHub plugins:
- GitHub webhook support
- GitHub OAuth authentication
- Multi-branch pipeline support
- Pull request integration

## Access

After installation, Jenkins will be available at:
- **URL**: `http://jenkins.local` (or your configured hostname)
- **Username**: `admin` (or your configured username)
- **Password**: `admin123` (or your configured password)

## Docker Pipeline Usage

The chart includes sample pipeline templates that demonstrate:
- Building Docker images using DinD
- Pushing to container registries
- Deploying to Kubernetes
- GitHub webhook integration

## Uninstallation

```bash
helm uninstall jenkins -n jenkins
```

## Troubleshooting

1. **Check pod status**:
   ```bash
   kubectl get pods -n jenkins
   ```

2. **View logs**:
   ```bash
   kubectl logs -n jenkins deployment/jenkins
   ```

3. **Check ingress**:
   ```bash
   kubectl get ingress -n jenkins
   ```

4. **Test Docker connectivity**:
   ```bash
   kubectl exec -n jenkins deployment/jenkins -- docker --host=tcp://jenkins-docker:2375 version
   ```

## Customization

You can customize the deployment by:
- Modifying `values.yaml`
- Creating custom pipeline templates
- Adding additional plugins
- Configuring different storage classes
- Setting up custom ingress rules
