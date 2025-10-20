# MongoDB Helm Chart

This Helm chart deploys MongoDB with replica set support on Kubernetes.

## Features

- **3-Replica MongoDB StatefulSet** with automatic replica set initialization
- **Authentication enabled** with root user/password
- **Persistent storage** with configurable storage class and size
- **Headless service** for StatefulSet pod communication
- **Regular service** for external access
- **Health checks** with liveness and readiness probes
- **Configurable resources** and security contexts

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- Storage class for persistent volumes

## Installation

### 1. Deploy MongoDB with default values

```bash
helm install mongodb ./mongodb --namespace demo-apps --create-namespace
```

### 2. Deploy with custom values

```bash
helm install mongodb ./mongodb \
  --namespace demo-apps \
  --create-namespace \
  --set replicaCount=3 \
  --set mongodb.auth.rootPassword=your-secure-password \
  --set persistence.size=20Gi
```

### 3. Deploy with values file

```bash
helm install mongodb ./mongodb \
  --namespace demo-apps \
  --create-namespace \
  --values custom-values.yaml
```

## Configuration

### Key Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of MongoDB replicas | `3` |
| `image.repository` | MongoDB image repository | `mongo` |
| `image.tag` | MongoDB image tag | `7.0` |
| `mongodb.auth.enabled` | Enable authentication | `true` |
| `mongodb.auth.rootUsername` | Root username | `admin` |
| `mongodb.auth.rootPassword` | Root password | `root123` |
| `mongodb.replicaSet.enabled` | Enable replica set | `true` |
| `mongodb.replicaSet.name` | Replica set name | `rs0` |
| `persistence.enabled` | Enable persistent storage | `true` |
| `persistence.size` | Storage size | `10Gi` |
| `service.type` | Service type | `ClusterIP` |
| `service.nodePort` | NodePort for external access | `30017` |

### Example values.yaml

```yaml
replicaCount: 3

image:
  repository: mongo
  tag: "7.0"

mongodb:
  auth:
    enabled: true
    rootUsername: admin
    rootPassword: secure-password
    database: myapp
  replicaSet:
    enabled: true
    name: rs0

persistence:
  enabled: true
  storageClass: "fast-ssd"
  size: 20Gi

service:
  type: NodePort
  nodePort: 30017

resources:
  limits:
    cpu: 1000m
    memory: 2Gi
  requests:
    cpu: 500m
    memory: 1Gi
```

## Accessing MongoDB

### Internal Access (within cluster)

```bash
# Connect to primary replica
mongosh "mongodb://admin:root123@mongodb.demo-apps.svc.cluster.local:27017/myapp?authSource=admin"

# Connect to specific replica
mongosh "mongodb://admin:root123@mongodb-0.mongodb-headless.demo-apps.svc.cluster.local:27017/myapp?authSource=admin"
```

### External Access (via NodePort)

```bash
# Get the node IP
kubectl get nodes -o wide

# Connect via NodePort
mongosh "mongodb://admin:root123@<NODE_IP>:30017/myapp?authSource=admin"
```

### Using MongoDB Compass

**Connection String:**
```
mongodb://admin:root123@<NODE_IP>:30017/myapp?authSource=admin
```

**Individual Fields:**
- Host: `<NODE_IP>`
- Port: `30017`
- Username: `admin`
- Password: `root123`
- Authentication Database: `admin`
- Database: `myapp`

## Replica Set Management

### Check replica set status

```bash
# Connect to primary
mongosh "mongodb://admin:root123@mongodb.demo-apps.svc.cluster.local:27017/myapp?authSource=admin"

# In mongosh
rs.status()
```

### Add/Remove replicas

```bash
# Scale the StatefulSet
kubectl scale statefulset mongodb --replicas=5 -n demo-apps

# The init container will automatically add new replicas to the replica set
```

## Troubleshooting

### Check pod status

```bash
kubectl get pods -n demo-apps -l app.kubernetes.io/name=mongodb
```

### Check logs

```bash
# Check init container logs
kubectl logs mongodb-0 -c init-replica-set -n demo-apps

# Check MongoDB container logs
kubectl logs mongodb-0 -c mongodb -n demo-apps
```

### Check replica set status

```bash
kubectl exec -it mongodb-0 -n demo-apps -- mongosh --eval "rs.status()"
```

## Uninstallation

```bash
helm uninstall mongodb -n demo-apps
```

**Note:** This will delete the StatefulSet and services, but persistent volumes will remain. To delete persistent volumes, you need to manually delete the PVCs:

```bash
kubectl delete pvc -l app.kubernetes.io/name=mongodb -n demo-apps
```
