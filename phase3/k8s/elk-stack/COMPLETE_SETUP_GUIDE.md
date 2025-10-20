# Complete ELK Stack Setup Guide

This guide documents the complete setup of an ELK (Elasticsearch, Logstash, Kibana) stack on Kubernetes with a sample log generator application.

## 📋 Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Architecture](#architecture)
4. [Step-by-Step Setup](#step-by-step-setup)
5. [Configuration Details](#configuration-details)
6. [Access Methods](#access-methods)
7. [Sample Application](#sample-application)
8. [Troubleshooting](#troubleshooting)
9. [Maintenance](#maintenance)

## 🎯 Overview

This ELK stack setup provides:
- **Elasticsearch**: Search and analytics engine for storing logs
- **Logstash**: Data processing pipeline for ingesting and transforming logs
- **Kibana**: Web interface for visualizing and exploring log data
- **Sample Log Generator**: Python application that generates realistic log data
- **Kubernetes Deployment**: All components running in containers
- **Ingress Access**: External access via friendly domain names

## 🔧 Prerequisites

### System Requirements
- **Kubernetes cluster** (minikube, kind, or cloud provider)
- **kubectl** configured to access your cluster
- **At least 4GB RAM** and 2 CPU cores available
- **Nginx Ingress Controller** installed
- **Python 3.6+** (for sample application)

### Software Dependencies
```bash
# Check kubectl
kubectl version --client

# Check cluster access
kubectl cluster-info

# Check ingress controller
kubectl get pods -n ingress-nginx
```

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────┐    ┌─────────────┐
│  Log Generator  │───▶│   Ingress    │───▶│  Logstash   │───▶│Elasticsearch│
│   (Python App)  │    │  (Nginx)     │    │ (Processing)│    │  (Storage)  │
└─────────────────┘    └──────────────┘    └─────────────┘    └─────────────┘
                                                                    │
                                                                    ▼
                                                              ┌─────────────┐
                                                              │   Kibana    │
                                                              │ (Visualize) │
                                                              └─────────────┘
```

### Data Flow
1. **Log Generator** creates realistic log entries
2. **Ingress** routes traffic to Logstash
3. **Logstash** processes and enriches logs
4. **Elasticsearch** stores logs in searchable indices
5. **Kibana** provides web interface for log exploration

## 🚀 Step-by-Step Setup

### Step 1: Create Directory Structure

```bash
# Create main directory
mkdir -p elk-stack/{elasticsearch,logstash,kibana,sample-app}

# Create subdirectories
mkdir -p elk-stack/logstash/pipeline
```

### Step 2: Deploy Namespace

```bash
# Create namespace
kubectl apply -f namespace.yaml
```

**File: `namespace.yaml`**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: elastic-stack
  labels:
    name: elastic-stack
    app: elk-stack
```

### Step 3: Deploy Elasticsearch

**File: `elasticsearch/configmap.yaml`**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: elasticsearch-config
  namespace: elastic-stack
data:
  elasticsearch.yml: |
    cluster.name: "docker-cluster"
    network.host: 0.0.0.0
    discovery.type: single-node
    xpack.security.enabled: false
    xpack.security.enrollment.enabled: false
    xpack.security.http.ssl.enabled: false
    xpack.security.transport.ssl.enabled: false
    xpack.monitoring.collection.enabled: true
    bootstrap.memory_lock: true
    action.auto_create_index: true
    logger.level: INFO
```

**File: `elasticsearch/pvc.yaml`**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: elasticsearch-data
  namespace: elastic-stack
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: standard
```

**File: `elasticsearch/deployment.yaml`**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: elasticsearch
  namespace: elastic-stack
  labels:
    app: elasticsearch
spec:
  replicas: 1
  selector:
    matchLabels:
      app: elasticsearch
  template:
    metadata:
      labels:
        app: elasticsearch
    spec:
      containers:
      - name: elasticsearch
        image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
        ports:
        - containerPort: 9200
          name: http
        - containerPort: 9300
          name: transport
        env:
        - name: "ES_JAVA_OPTS"
          value: "-Xms1g -Xmx1g"
        - name: "discovery.type"
          value: "single-node"
        - name: "xpack.security.enabled"
          value: "false"
        - name: "xpack.security.enrollment.enabled"
          value: "false"
        - name: "xpack.security.http.ssl.enabled"
          value: "false"
        - name: "xpack.security.transport.ssl.enabled"
          value: "false"
        volumeMounts:
        - name: elasticsearch-data
          mountPath: /usr/share/elasticsearch/data
        - name: elasticsearch-config
          mountPath: /usr/share/elasticsearch/config/elasticsearch.yml
          subPath: elasticsearch.yml
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
        livenessProbe:
          httpGet:
            path: /_cluster/health
            port: 9200
          initialDelaySeconds: 60
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /_cluster/health
            port: 9200
          initialDelaySeconds: 30
          periodSeconds: 10
      volumes:
      - name: elasticsearch-data
        persistentVolumeClaim:
          claimName: elasticsearch-data
      - name: elasticsearch-config
        configMap:
          name: elasticsearch-config
      securityContext:
        fsGroup: 1000
        runAsUser: 1000
```

**File: `elasticsearch/service.yaml`**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: elasticsearch
  namespace: elastic-stack
  labels:
    app: elasticsearch
spec:
  selector:
    app: elasticsearch
  ports:
  - name: http
    port: 9200
    targetPort: 9200
    protocol: TCP
  - name: transport
    port: 9300
    targetPort: 9300
    protocol: TCP
  type: ClusterIP
```

### Step 4: Deploy Logstash

**File: `logstash/configmap.yaml`**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: logstash-config
  namespace: elastic-stack
data:
  logstash.yml: |
    http.host: "0.0.0.0"
    xpack.monitoring.elasticsearch.hosts: [ "http://elasticsearch.elastic-stack.svc.cluster.local:9200" ]
    xpack.monitoring.enabled: true
    pipeline.workers: 2
    pipeline.batch.size: 1000
    pipeline.batch.delay: 50
  logstash.conf: |
    input {
      # File input for log files
      file {
        path => "/var/log/*.log"
        type => "system"
        start_position => "beginning"
      }
      
      # Beats input for filebeat
      beats {
        port => 5044
      }
      
      # TCP input for applications
      tcp {
        port => 5000
        codec => json_lines
      }
      
      # HTTP input for webhooks
      http {
        port => 8080
        codec => json
      }
    }

    filter {
      # Parse JSON logs
      if [message] =~ /^\{.*\}$/ {
        json {
          source => "message"
        }
      }
      
      # Parse common log formats
      if [type] == "system" {
        grok {
          match => { "message" => "%{SYSLOGTIMESTAMP:timestamp} %{IPORHOST:host} %{PROG:program}: %{GREEDYDATA:message}" }
        }
      }
      
      # Parse Apache/Nginx logs
      if [type] == "apache" {
        grok {
          match => { "message" => "%{COMBINEDAPACHELOG}" }
        }
      }
      
      # Add timestamp
      date {
        match => [ "timestamp", "dd/MMM/yyyy:HH:mm:ss Z" ]
      }
      
      # Remove unnecessary fields
      mutate {
        remove_field => [ "host", "timestamp" ]
      }
    }

    output {
      # Output to Elasticsearch
      elasticsearch {
        hosts => ["elasticsearch.elastic-stack.svc.cluster.local:9200"]
        index => "logstash-%{+YYYY.MM.dd}"
      }
      
      # Debug output (remove in production)
      stdout {
        codec => rubydebug
      }
    }
```

**File: `logstash/deployment.yaml`**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: logstash
  namespace: elastic-stack
  labels:
    app: logstash
spec:
  replicas: 1
  selector:
    matchLabels:
      app: logstash
  template:
    metadata:
      labels:
        app: logstash
    spec:
      containers:
      - name: logstash
        image: docker.elastic.co/logstash/logstash:8.11.0
        ports:
        - containerPort: 5044
          name: beats
        - containerPort: 5000
          name: tcp
        - containerPort: 8080
          name: http
        env:
        - name: "LS_JAVA_OPTS"
          value: "-Xms512m -Xmx512m"
        - name: "ELASTICSEARCH_HOSTS"
          value: "http://elasticsearch:9200"
        volumeMounts:
        - name: logstash-config
          mountPath: /usr/share/logstash/config/logstash.yml
          subPath: logstash.yml
        - name: logstash-pipeline
          mountPath: /usr/share/logstash/pipeline/logstash.conf
          subPath: logstash.conf
        - name: log-data
          mountPath: /var/log
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          exec:
            command:
            - /bin/bash
            - -c
            - "curl -f http://localhost:9600/_node/stats || exit 1"
          initialDelaySeconds: 60
          periodSeconds: 30
        readinessProbe:
          exec:
            command:
            - /bin/bash
            - -c
            - "curl -f http://localhost:9600/_node/stats || exit 1"
          initialDelaySeconds: 30
          periodSeconds: 10
      volumes:
      - name: logstash-config
        configMap:
          name: logstash-config
      - name: logstash-pipeline
        configMap:
          name: logstash-config
      - name: log-data
        hostPath:
          path: /var/log
          type: Directory
```

**File: `logstash/service.yaml`**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: logstash
  namespace: elastic-stack
  labels:
    app: logstash
spec:
  selector:
    app: logstash
  ports:
  - name: beats
    port: 5044
    targetPort: 5044
    protocol: TCP
  - name: tcp
    port: 5000
    targetPort: 5000
    protocol: TCP
  - name: http
    port: 8080
    targetPort: 8080
    protocol: TCP
  type: ClusterIP
```

### Step 5: Deploy Kibana

**File: `kibana/configmap.yaml`**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: kibana-config
  namespace: elastic-stack
data:
  kibana.yml: |
    server.name: kibana
    server.host: "0.0.0.0"
    elasticsearch.hosts: [ "http://elasticsearch:9200" ]
    xpack.security.enabled: false
    xpack.encryptedSavedObjects.encryptionKey: "something_at_least_32_characters_long"
    xpack.reporting.encryptionKey: "something_at_least_32_characters_long"
    xpack.security.encryptionKey: "something_at_least_32_characters_long"
    # Monitoring
    xpack.monitoring.ui.container.elasticsearch.enabled: true
    # Default app (removed invalid config)
    # Logging
    logging.appenders:
      console:
        type: console
        layout:
          type: json
    logging.loggers:
      - name: http.server.response
        appenders: [console]
        level: error
```

**File: `kibana/deployment.yaml`**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kibana
  namespace: elastic-stack
  labels:
    app: kibana
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kibana
  template:
    metadata:
      labels:
        app: kibana
    spec:
      containers:
      - name: kibana
        image: docker.elastic.co/kibana/kibana:8.11.0
        ports:
        - containerPort: 5601
          name: http
        env:
        - name: "ELASTICSEARCH_HOSTS"
          value: "http://elasticsearch:9200"
        - name: "SERVER_NAME"
          value: "kibana"
        - name: "SERVER_HOST"
          value: "0.0.0.0"
        volumeMounts:
        - name: kibana-config
          mountPath: /usr/share/kibana/config/kibana.yml
          subPath: kibana.yml
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /api/status
            port: 5601
          initialDelaySeconds: 60
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /api/status
            port: 5601
          initialDelaySeconds: 30
          periodSeconds: 10
      volumes:
      - name: kibana-config
        configMap:
          name: kibana-config
```

**File: `kibana/service.yaml`**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: kibana
  namespace: elastic-stack
  labels:
    app: kibana
spec:
  selector:
    app: kibana
  ports:
  - name: http
    port: 5601
    targetPort: 5601
    protocol: TCP
  type: ClusterIP
```

### Step 6: Deploy Ingress

**File: `ingress.yaml`**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: elk-stack-ingress
  namespace: elastic-stack
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
spec:
  ingressClassName: nginx
  rules:
  - host: kibana.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: kibana
            port:
              number: 5601
  - host: elasticsearch.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: elasticsearch
            port:
              number: 9200
  - host: logstash.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: logstash
            port:
              number: 8080
```

### Step 7: Create Kustomization Files

**File: `kustomization.yaml`**
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: elastic-stack

resources:
  - namespace.yaml
  - elasticsearch/
  - logstash/
  - kibana/
  - ingress.yaml

commonLabels:
  app.kubernetes.io/name: elk-stack
  app.kubernetes.io/version: "8.11.0"
  app.kubernetes.io/component: logging

images:
  - name: docker.elastic.co/elasticsearch/elasticsearch
    newTag: "8.11.0"
  - name: docker.elastic.co/logstash/logstash
    newTag: "8.11.0"
  - name: docker.elastic.co/kibana/kibana
    newTag: "8.11.0"
```

**File: `elasticsearch/kustomization.yaml`**
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - configmap.yaml
  - pvc.yaml
  - deployment.yaml
  - service.yaml
```

**File: `logstash/kustomization.yaml`**
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - configmap.yaml
  - deployment.yaml
  - service.yaml
```

**File: `kibana/kustomization.yaml`**
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - configmap.yaml
  - deployment.yaml
  - service.yaml
```

### Step 8: Deploy the Stack

```bash
# Deploy using Kustomize
kubectl apply -k .

# Or deploy manually
kubectl apply -f namespace.yaml
kubectl apply -f elasticsearch/
kubectl apply -f logstash/
kubectl apply -f kibana/
kubectl apply -f ingress.yaml
```

### Step 9: Configure /etc/hosts

```bash
# Add these entries to /etc/hosts
echo "192.168.39.200 kibana.local" | sudo tee -a /etc/hosts
echo "192.168.39.200 elasticsearch.local" | sudo tee -a /etc/hosts
echo "192.168.39.200 logstash.local" | sudo tee -a /etc/hosts
```

## 🌐 Access Methods

### Via Ingress (Recommended)
- **Kibana**: http://kibana.local
- **Elasticsearch**: http://elasticsearch.local:9200
- **Logstash**: http://logstash.local:8080

### Via Port Forwarding
```bash
# Kibana
kubectl port-forward svc/kibana 5601:5601 -n elastic-stack

# Elasticsearch
kubectl port-forward svc/elasticsearch 9200:9200 -n elastic-stack

# Logstash
kubectl port-forward svc/logstash 8080:8080 -n elastic-stack
```

## 📱 Sample Application

### Log Generator Setup

**File: `sample-app/log-generator.py`**
```python
#!/usr/bin/env python3
"""
Sample Log Generator for ELK Stack
This application generates various types of log entries and sends them to Logstash
"""

import requests
import time
import random
import json
from datetime import datetime
import sys

# Configuration
LOGSTASH_URL = "http://logstash.local"
SERVICES = ["web-app", "api-gateway", "database", "auth-service", "payment-service", "notification-service"]
LOG_LEVELS = ["info", "warn", "error", "debug"]
USERS = ["user001", "user002", "user003", "user004", "user005"]
ENDPOINTS = ["/api/users", "/api/orders", "/api/products", "/api/auth/login", "/api/payments", "/api/notifications"]

def generate_log_entry():
    """Generate a random log entry"""
    service = random.choice(SERVICES)
    level = random.choice(LOG_LEVELS)
    user = random.choice(USERS)
    endpoint = random.choice(ENDPOINTS)
    
    # Generate different types of log messages based on level
    if level == "error":
        messages = [
            f"Database connection failed for user {user}",
            f"API endpoint {endpoint} returned 500 error",
            f"Authentication failed for user {user}",
            f"Payment processing failed for order {random.randint(1000, 9999)}",
            f"External service timeout for {service}"
        ]
    elif level == "warn":
        messages = [
            f"High response time detected for {endpoint}",
            f"Rate limit approaching for user {user}",
            f"Deprecated API endpoint {endpoint} used",
            f"Low disk space warning on {service}",
            f"Unusual activity detected for user {user}"
        ]
    elif level == "debug":
        messages = [
            f"Processing request for {endpoint}",
            f"Cache miss for user {user}",
            f"Database query executed successfully",
            f"Session created for user {user}",
            f"Configuration loaded for {service}"
        ]
    else:  # info
        messages = [
            f"User {user} logged in successfully",
            f"API request to {endpoint} completed",
            f"Order {random.randint(1000, 9999)} processed",
            f"Email sent to user {user}",
            f"Backup completed for {service}",
            f"New user registration: {user}",
            f"Payment processed for order {random.randint(1000, 9999)}",
            f"Notification sent to user {user}"
        ]
    
    message = random.choice(messages)
    
    # Create log entry
    log_entry = {
        "timestamp": datetime.now().isoformat(),
        "level": level,
        "service": service,
        "message": message,
        "user_id": user,
        "endpoint": endpoint,
        "response_time": random.randint(10, 500),
        "status_code": random.choice([200, 201, 400, 401, 404, 500]),
        "ip_address": f"192.168.1.{random.randint(1, 254)}",
        "session_id": f"session_{random.randint(10000, 99999)}",
        "request_id": f"req_{random.randint(100000, 999999)}"
    }
    
    return log_entry

def send_log_to_logstash(log_entry):
    """Send log entry to Logstash"""
    try:
        response = requests.post(LOGSTASH_URL, json=log_entry, timeout=5)
        if response.status_code == 200:
            print(f"✅ Sent: {log_entry['level'].upper()} - {log_entry['message']}")
            return True
        else:
            print(f"❌ Failed to send log: HTTP {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌ Connection error: {e}")
        return False

def main():
    """Main application loop"""
    print("🚀 Starting Sample Log Generator for ELK Stack")
    print(f"📡 Sending logs to: {LOGSTASH_URL}")
    print("⏹️  Press Ctrl+C to stop")
    print("-" * 50)
    
    log_count = 0
    
    try:
        while True:
            # Generate and send log entry
            log_entry = generate_log_entry()
            success = send_log_to_logstash(log_entry)
            
            if success:
                log_count += 1
            
            # Wait before sending next log (1-3 seconds)
            wait_time = random.uniform(1, 3)
            time.sleep(wait_time)
            
            # Print summary every 10 logs
            if log_count % 10 == 0:
                print(f"📊 Total logs sent: {log_count}")
                
    except KeyboardInterrupt:
        print(f"\n🛑 Stopped. Total logs sent: {log_count}")
        sys.exit(0)

if __name__ == "__main__":
    main()
```

**File: `sample-app/requirements.txt`**
```
requests==2.31.0
```

**File: `sample-app/start-logs.sh`**
```bash
#!/bin/bash

# Sample Log Generator Startup Script for ELK Stack

echo "🚀 ELK Stack Sample Log Generator"
echo "================================="

# Check if ingress is accessible
echo "🔍 Checking Logstash ingress accessibility..."

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 is not installed"
    exit 1
fi

# Check if requests module is available
if ! python3 -c "import requests" 2>/dev/null; then
    echo "📦 Installing required Python packages..."
    pip3 install requests
fi

# Test connection to Logstash via ingress
echo "🔍 Testing connection to Logstash via ingress..."
if curl -s http://logstash.local > /dev/null; then
    echo "✅ Logstash ingress is accessible"
else
    echo "❌ Cannot connect to Logstash via ingress (logstash.local)"
    echo "💡 Make sure:"
    echo "   1. Ingress is deployed: kubectl get ingress -n elastic-stack"
    echo "   2. /etc/hosts has: 192.168.39.200 logstash.local"
    echo "   3. Nginx ingress controller is running"
    exit 1
fi

echo ""
echo "🎯 Starting log generator..."
echo "📊 Logs will be sent to your ELK stack"
echo "⏹️  Press Ctrl+C to stop"
echo ""

# Start the log generator
python3 "$(dirname "$0")/log-generator.py"
```

### Running the Sample Application

```bash
# Install dependencies
pip3 install -r sample-app/requirements.txt

# Make scripts executable
chmod +x sample-app/log-generator.py
chmod +x sample-app/start-logs.sh

# Start the log generator
cd sample-app
python3 log-generator.py

# Or use the startup script
./start-logs.sh
```

## 🔍 Troubleshooting

### Common Issues

#### 1. Pods Not Starting
```bash
# Check pod status
kubectl get pods -n elastic-stack

# Check pod logs
kubectl logs -f deployment/elasticsearch -n elastic-stack
kubectl logs -f deployment/logstash -n elastic-stack
kubectl logs -f deployment/kibana -n elastic-stack

# Check pod events
kubectl describe pod <pod-name> -n elastic-stack
```

#### 2. Ingress Not Working
```bash
# Check ingress status
kubectl get ingress -n elastic-stack

# Check ingress controller
kubectl get pods -n ingress-nginx

# Test connectivity
curl -I http://kibana.local
```

#### 3. Logstash Connection Issues
```bash
# Test Logstash connectivity
curl -X POST http://logstash.local -H "Content-Type: application/json" -d '{"test":"message"}'

# Check Logstash logs
kubectl logs -f deployment/logstash -n elastic-stack
```

#### 4. Elasticsearch Issues
```bash
# Check cluster health
kubectl exec -it deployment/elasticsearch -n elastic-stack -- curl -X GET "localhost:9200/_cluster/health?pretty"

# Check indices
kubectl exec -it deployment/elasticsearch -n elastic-stack -- curl -X GET "localhost:9200/_cat/indices?v"
```

### Useful Commands

```bash
# Check all resources
kubectl get all -n elastic-stack

# Check services
kubectl get services -n elastic-stack

# Check ingress
kubectl get ingress -n elastic-stack

# Check persistent volumes
kubectl get pvc -n elastic-stack

# View logs
kubectl logs -f deployment/elasticsearch -n elastic-stack
kubectl logs -f deployment/logstash -n elastic-stack
kubectl logs -f deployment/kibana -n elastic-stack

# Port forward for testing
kubectl port-forward svc/kibana 5601:5601 -n elastic-stack
kubectl port-forward svc/elasticsearch 9200:9200 -n elastic-stack
kubectl port-forward svc/logstash 8080:8080 -n elastic-stack
```

## 🛠️ Maintenance

### Scaling
```bash
# Scale Logstash
kubectl scale deployment logstash --replicas=3 -n elastic-stack

# Scale Kibana
kubectl scale deployment kibana --replicas=2 -n elastic-stack
```

### Updates
```bash
# Update image versions in kustomization.yaml
kubectl apply -k .
```

### Backup
```bash
# Backup Elasticsearch data
kubectl exec -it deployment/elasticsearch -n elastic-stack -- curl -X POST "localhost:9200/_snapshot/backup_repo/snapshot_1?wait_for_completion=true"
```

### Cleanup
```bash
# Remove the entire stack
kubectl delete namespace elastic-stack

# Or use the cleanup script
./cleanup.sh
```

## 📊 Monitoring

### Health Checks
```bash
# Elasticsearch health
kubectl exec -it deployment/elasticsearch -n elastic-stack -- curl -s "localhost:9200/_cluster/health?pretty"

# Logstash stats
kubectl exec -it deployment/logstash -n elastic-stack -- curl -s "localhost:9600/_node/stats?pretty"

# Kibana status
kubectl exec -it deployment/kibana -n elastic-stack -- curl -s "localhost:5601/api/status"
```

### Resource Usage
```bash
# Check resource usage
kubectl top pods -n elastic-stack

# Check node resources
kubectl top nodes
```

## 🎯 Next Steps

1. **Create Dashboards**: Build visualizations in Kibana
2. **Set up Alerts**: Configure monitoring and alerting
3. **Add More Data Sources**: Integrate with other applications
4. **Scale the Stack**: Add more nodes for production use
5. **Security**: Enable authentication and encryption
6. **Backup Strategy**: Implement regular backups

## 📚 Additional Resources

- [Elasticsearch Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
- [Logstash Documentation](https://www.elastic.co/guide/en/logstash/current/index.html)
- [Kibana Documentation](https://www.elastic.co/guide/en/kibana/current/index.html)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

---

**Created by**: ELK Stack Setup Guide  
**Version**: 1.0  
**Last Updated**: October 2025





