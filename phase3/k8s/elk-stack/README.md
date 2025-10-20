# ELK Stack Deployment

This directory contains Kubernetes manifests and configurations for deploying an ELK (Elasticsearch, Logstash, Kibana) stack.

## Architecture Overview

- **Elasticsearch**: Search and analytics engine
- **Logstash**: Data processing pipeline
- **Kibana**: Data visualization and exploration

## Directory Structure

```
elk-stack/
├── elasticsearch/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   └── pvc.yaml
├── logstash/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   └── pipeline/
│       └── logstash.conf
├── kibana/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── configmap.yaml
├── namespace.yaml
├── ingress.yaml
└── deploy.sh
```

## Prerequisites

- Kubernetes cluster (minikube, kind, or cloud provider)
- kubectl configured to access your cluster
- At least 4GB RAM and 2 CPU cores available

## Quick Start

1. Deploy the namespace:
   ```bash
   kubectl apply -f namespace.yaml
   ```

2. Deploy Elasticsearch:
   ```bash
   kubectl apply -f elasticsearch/
   ```

3. Deploy Logstash:
   ```bash
   kubectl apply -f logstash/
   ```

4. Deploy Kibana:
   ```bash
   kubectl apply -f kibana/
   ```

5. Deploy ingress (optional):
   ```bash
   kubectl apply -f ingress.yaml
   ```

6. Or use the deployment script:
   ```bash
   chmod +x deploy.sh
   ./deploy.sh
   ```

## Access

- **Kibana**: http://kibana.local (or your configured domain)
- **Elasticsearch**: http://elasticsearch.elastic-stack.svc.cluster.local:9200

## Default Credentials

- Username: `elastic`
- Password: `changeme` (change this in production!)

## Monitoring

Check pod status:
```bash
kubectl get pods -n elastic-stack
```

Check logs:
```bash
kubectl logs -f deployment/elasticsearch -n elastic-stack
kubectl logs -f deployment/logstash -n elastic-stack
kubectl logs -f deployment/kibana -n elastic-stack
```

## Troubleshooting

See the troubleshooting section in the README for common issues and solutions.
