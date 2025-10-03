#!/bin/bash

# Monitoring Access Script
# This script provides easy access to all monitoring tools

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔍 Monitoring Tools Access${NC}"
echo "=================================="

# Function to check if pod is ready
check_pod_ready() {
    local namespace=$1
    local pod_name=$2
    local timeout=${3:-60}
    
    echo -e "${YELLOW}⏳ Waiting for ${pod_name} to be ready...${NC}"
    
    for i in $(seq 1 $timeout); do
        if kubectl get pod -n "$namespace" | grep "$pod_name" | grep -q "Running"; then
            echo -e "${GREEN}✅ ${pod_name} is ready!${NC}"
            return 0
        fi
        sleep 2
    done
    
    echo -e "${RED}❌ ${pod_name} is not ready after ${timeout} seconds${NC}"
    return 1
}

# Function to get Grafana password
get_grafana_password() {
    echo -e "${BLUE}🔑 Grafana Admin Password:${NC}"
    kubectl get secret prometheus-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 -d 2>/dev/null && echo || echo "Password not available yet"
}

# Function to get ArgoCD password
get_argocd_password() {
    echo -e "${BLUE}🔑 ArgoCD Admin Password:${NC}"
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null && echo || echo "Password not available yet"
}

# Function to get Jenkins password
get_jenkins_password() {
    echo -e "${BLUE}🔑 Jenkins Admin Password:${NC}"
    kubectl exec --namespace jenkins -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password 2>/dev/null && echo || echo "Password not available yet"
}

# Function to show access information
show_access_info() {
    echo -e "${GREEN}📊 Monitoring Access Information${NC}"
    echo "=================================="
    
    # Get minikube IP
    MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "localhost")
    
    echo -e "${YELLOW}🌐 Web Access (via Ingress):${NC}"
    echo "  • Grafana:     http://grafana.local"
    echo "  • Prometheus:  http://prometheus.local"
    echo "  • Alertmanager: http://alertmanager.local"
    echo "  • ArgoCD:      http://argocd.local"
    echo "  • Jenkins:     http://jenkins.local"
    echo ""
    echo -e "${YELLOW}🔧 Port Forward Access:${NC}"
    echo "  • Grafana:     kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
    echo "  • Prometheus:  kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
    echo "  • ArgoCD:      kubectl port-forward -n argocd svc/argocd-server 8080:443"
    echo "  • Jenkins:     kubectl port-forward -n jenkins svc/jenkins 8081:8080"
    echo ""
    echo -e "${YELLOW}📱 Minikube IP Access:${NC}"
    echo "  • Minikube IP: ${MINIKUBE_IP}"
    echo "  • Add to /etc/hosts: ${MINIKUBE_IP} grafana.local prometheus.local alertmanager.local argocd.local jenkins.local"
    echo ""
}

# Function to start port forwarding
start_port_forward() {
    local service=$1
    local namespace=$2
    local local_port=$3
    local remote_port=$4
    
    echo -e "${YELLOW}🚀 Starting port forward for ${service}...${NC}"
    echo "Access at: http://localhost:${local_port}"
    kubectl port-forward -n "$namespace" "svc/${service}" "${local_port}:${remote_port}"
}

# Main menu
case "${1:-menu}" in
    "menu")
        show_access_info
        echo -e "${GREEN}🔐 Passwords:${NC}"
        echo "============="
        get_grafana_password
        get_argocd_password
        get_jenkins_password
        echo ""
        echo -e "${YELLOW}📋 Available Commands:${NC}"
        echo "  $0 grafana     - Start Grafana port forward"
        echo "  $0 prometheus  - Start Prometheus port forward"
        echo "  $0 argocd      - Start ArgoCD port forward"
        echo "  $0 jenkins     - Start Jenkins port forward"
        echo "  $0 status      - Check all pod status"
        echo "  $0 passwords   - Show all passwords"
        echo "  $0 ingress     - Show ingress information"
        ;;
    "grafana")
        check_pod_ready "monitoring" "prometheus-grafana"
        start_port_forward "prometheus-grafana" "monitoring" "3000" "80"
        ;;
    "prometheus")
        check_pod_ready "monitoring" "prometheus-kube-prometheus-prometheus"
        start_port_forward "prometheus-kube-prometheus-prometheus" "monitoring" "9090" "9090"
        ;;
    "argocd")
        check_pod_ready "argocd" "argocd-server"
        start_port_forward "argocd-server" "argocd" "8080" "443"
        ;;
    "jenkins")
        check_pod_ready "jenkins" "jenkins"
        start_port_forward "jenkins" "jenkins" "8081" "8080"
        ;;
    "status")
        echo -e "${GREEN}📊 Pod Status${NC}"
        echo "============="
        echo -e "${YELLOW}Monitoring Namespace:${NC}"
        kubectl get pods -n monitoring
        echo ""
        echo -e "${YELLOW}ArgoCD Namespace:${NC}"
        kubectl get pods -n argocd
        echo ""
        echo -e "${YELLOW}Jenkins Namespace:${NC}"
        kubectl get pods -n jenkins
        echo ""
        echo -e "${YELLOW}Ingress Status:${NC}"
        kubectl get ingress --all-namespaces
        echo ""
        echo -e "${YELLOW}ArgoCD Image Updater:${NC}"
        kubectl get pods -n argocd | grep image-updater || echo "Image Updater not running"
        ;;
    "passwords")
        echo -e "${GREEN}🔐 All Passwords${NC}"
        echo "==============="
        get_grafana_password
        get_argocd_password
        get_jenkins_password
        ;;
    "ingress")
        echo -e "${GREEN}🌐 Ingress Information${NC}"
        echo "====================="
        kubectl get ingress --all-namespaces
        echo ""
        echo -e "${YELLOW}To access via hostnames, add to /etc/hosts:${NC}"
        MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "localhost")
        echo "${MINIKUBE_IP} grafana.local prometheus.local alertmanager.local argocd.local jenkins.local"
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        echo "Run '$0 menu' to see available commands"
        exit 1
        ;;
esac
