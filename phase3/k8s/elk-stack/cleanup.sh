#!/bin/bash

# ELK Stack Cleanup Script
# This script removes the complete ELK stack from Kubernetes

set -e

echo "🧹 Starting ELK Stack Cleanup..."

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

# Confirm deletion
read -p "Are you sure you want to delete the entire ELK stack? This will remove all data! (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Cleanup cancelled by user"
    exit 0
fi

# Delete namespace (this will delete everything in the namespace)
print_status "Deleting elastic-stack namespace..."
kubectl delete namespace elastic-stack --ignore-not-found=true
print_success "ELK Stack cleanup completed"

print_success "🎉 ELK Stack has been completely removed!"
