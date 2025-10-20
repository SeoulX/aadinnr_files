#!/bin/bash

# ELK Stack Deployment Script
# This script deploys the complete ELK stack to Kubernetes

set -e

echo "🚀 Starting ELK Stack Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if kubectl can connect to cluster
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi

print_status "Connected to Kubernetes cluster: $(kubectl config current-context)"

# Create namespace
print_status "Creating namespace..."
kubectl apply -f namespace.yaml
print_success "Namespace created"

# Deploy Elasticsearch
print_status "Deploying Elasticsearch..."
kubectl apply -f elasticsearch/
print_success "Elasticsearch deployment created"

# Wait for Elasticsearch to be ready
print_status "Waiting for Elasticsearch to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/elasticsearch -n elastic-stack
print_success "Elasticsearch is ready"

# Deploy Logstash
print_status "Deploying Logstash..."
kubectl apply -f logstash/
print_success "Logstash deployment created"

# Wait for Logstash to be ready
print_status "Waiting for Logstash to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/logstash -n elastic-stack
print_success "Logstash is ready"

# Deploy Kibana
print_status "Deploying Kibana..."
kubectl apply -f kibana/
print_success "Kibana deployment created"

# Wait for Kibana to be ready
print_status "Waiting for Kibana to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/kibana -n elastic-stack
print_success "Kibana is ready"

# Deploy Ingress (optional)
if [ "$1" = "--with-ingress" ]; then
    print_status "Deploying Ingress..."
    kubectl apply -f ingress.yaml
    print_success "Ingress created"
    print_warning "Make sure to add the following entries to your /etc/hosts file:"
    echo "127.0.0.1 kibana.local"
    echo "127.0.0.1 elasticsearch.local"
    echo "127.0.0.1 logstash.local"
fi

# Show deployment status
print_status "Deployment completed! Here's the status:"
echo ""
kubectl get pods -n elastic-stack
echo ""
kubectl get services -n elastic-stack
echo ""

# Show access information
print_success "ELK Stack is now running!"
echo ""
print_status "Access Information:"
echo "• Kibana: http://kibana.local (or port-forward: kubectl port-forward svc/kibana 5601:5601 -n elastic-stack)"
echo "• Elasticsearch: http://elasticsearch.local:9200 (or port-forward: kubectl port-forward svc/elasticsearch 9200:9200 -n elastic-stack)"
echo "• Logstash: http://logstash.local:8080 (or port-forward: kubectl port-forward svc/logstash 8080:8080 -n elastic-stack)"
echo ""

print_status "Useful commands:"
echo "• Check pod status: kubectl get pods -n elastic-stack"
echo "• View logs: kubectl logs -f deployment/elasticsearch -n elastic-stack"
echo "• Port forward Kibana: kubectl port-forward svc/kibana 5601:5601 -n elastic-stack"
echo "• Delete everything: kubectl delete namespace elastic-stack"
echo ""

print_success "🎉 ELK Stack deployment completed successfully!"
