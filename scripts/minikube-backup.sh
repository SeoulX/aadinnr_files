#!/bin/bash

# Minikube Backup Script
# This script backs up all your minikube deployments and configurations

set -e

# Configuration
BACKUP_DIR="/home/andrian/aadinnr_files/backups"
DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="minikube_backup_${DATE}"
FULL_BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting Minikube Backup Process...${NC}"

# Create backup directory
mkdir -p "${FULL_BACKUP_PATH}"

# Function to backup namespace resources
backup_namespace() {
    local namespace=$1
    echo -e "${YELLOW}📦 Backing up namespace: ${namespace}${NC}"
    
    mkdir -p "${FULL_BACKUP_PATH}/namespaces/${namespace}"
    
    # Backup all resources in the namespace
    kubectl get all -n "${namespace}" -o yaml > "${FULL_BACKUP_PATH}/namespaces/${namespace}/all-resources.yaml" 2>/dev/null || true
    kubectl get configmaps -n "${namespace}" -o yaml > "${FULL_BACKUP_PATH}/namespaces/${namespace}/configmaps.yaml" 2>/dev/null || true
    kubectl get secrets -n "${namespace}" -o yaml > "${FULL_BACKUP_PATH}/namespaces/${namespace}/secrets.yaml" 2>/dev/null || true
    kubectl get ingress -n "${namespace}" -o yaml > "${FULL_BACKUP_PATH}/namespaces/${namespace}/ingress.yaml" 2>/dev/null || true
    kubectl get pvc -n "${namespace}" -o yaml > "${FULL_BACKUP_PATH}/namespaces/${namespace}/pvc.yaml" 2>/dev/null || true
    kubectl get pv -o yaml > "${FULL_BACKUP_PATH}/namespaces/${namespace}/pv.yaml" 2>/dev/null || true
}

# Function to backup Helm releases
backup_helm_releases() {
    echo -e "${YELLOW}📊 Backing up Helm releases...${NC}"
    
    mkdir -p "${FULL_BACKUP_PATH}/helm"
    
    # Get all Helm releases
    helm list --all-namespaces -o yaml > "${FULL_BACKUP_PATH}/helm/releases.yaml"
    
    # Backup each release's values
    for release in $(helm list --all-namespaces -q); do
        local namespace=$(helm list --all-namespaces | grep "${release}" | awk '{print $2}')
        echo "Backing up Helm release: ${release} in namespace: ${namespace}"
        helm get values "${release}" -n "${namespace}" > "${FULL_BACKUP_PATH}/helm/${release}-values.yaml" 2>/dev/null || true
    done
}

# Function to backup cluster-wide resources
backup_cluster_resources() {
    echo -e "${YELLOW}🌐 Backing up cluster-wide resources...${NC}"
    
    mkdir -p "${FULL_BACKUP_PATH}/cluster"
    
    kubectl get nodes -o yaml > "${FULL_BACKUP_PATH}/cluster/nodes.yaml"
    kubectl get namespaces -o yaml > "${FULL_BACKUP_PATH}/cluster/namespaces.yaml"
    kubectl get storageclass -o yaml > "${FULL_BACKUP_PATH}/cluster/storageclass.yaml"
    kubectl get clusterrole -o yaml > "${FULL_BACKUP_PATH}/cluster/clusterroles.yaml"
    kubectl get clusterrolebinding -o yaml > "${FULL_BACKUP_PATH}/cluster/clusterrolebindings.yaml"
}

# Function to create restore script
create_restore_script() {
    echo -e "${YELLOW}📝 Creating restore script...${NC}"
    
    cat > "${FULL_BACKUP_PATH}/restore.sh" << 'EOF'
#!/bin/bash

# Minikube Restore Script
# This script restores your minikube deployments from backup

set -e

BACKUP_DIR="/home/andrian/aadinnr_files/backups"
BACKUP_NAME=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if minikube is running
check_minikube() {
    if ! minikube status >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Minikube is not running. Starting minikube...${NC}"
        minikube start
    else
        echo -e "${GREEN}✅ Minikube is running${NC}"
    fi
}

# Function to wait for namespace to be ready
wait_for_namespace() {
    local namespace=$1
    local timeout=30
    local count=0
    
    while [ $count -lt $timeout ]; do
        if kubectl get namespace "$namespace" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Namespace $namespace is ready${NC}"
            return 0
        fi
        sleep 1
        count=$((count + 1))
    done
    
    echo -e "${RED}❌ Timeout waiting for namespace $namespace${NC}"
    return 1
}

# Function to restore resources safely
restore_resource() {
    local file=$1
    local description=$2
    
    if [ -f "$file" ] && [ -s "$file" ]; then
        echo -e "${BLUE}📄 Restoring $description...${NC}"
        if kubectl apply -f "$file" 2>/dev/null; then
            echo -e "${GREEN}✅ $description restored successfully${NC}"
        else
            echo -e "${YELLOW}⚠️  Warning: Some $description resources may have conflicts${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  No $description file found or file is empty${NC}"
    fi
}

if [ -z "$1" ]; then
    echo -e "${RED}❌ Please provide backup name as argument${NC}"
    echo "Usage: $0 <backup_name>"
    echo "Available backups:"
    ls -la "${BACKUP_DIR}" | grep minikube_backup || echo "No backups found"
    exit 1
fi

BACKUP_NAME="$1"
FULL_BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

if [ ! -d "${FULL_BACKUP_PATH}" ]; then
    echo -e "${RED}❌ Backup directory not found: ${FULL_BACKUP_PATH}${NC}"
    echo "Available backups:"
    ls -la "${BACKUP_DIR}" | grep minikube_backup || echo "No backups found"
    exit 1
fi

echo -e "${GREEN}🔄 Starting Minikube Restore Process...${NC}"
echo "Backup: ${BACKUP_NAME}"
echo "Path: ${FULL_BACKUP_PATH}"

# Check and start minikube if needed
check_minikube

# Wait for minikube to be ready
echo -e "${YELLOW}⏳ Waiting for minikube to be ready...${NC}"
sleep 10

# Restore cluster-wide resources
echo -e "${YELLOW}🌐 Restoring cluster-wide resources...${NC}"
restore_resource "${FULL_BACKUP_PATH}/cluster/namespaces.yaml" "namespaces"
restore_resource "${FULL_BACKUP_PATH}/cluster/storageclass.yaml" "storage classes"
restore_resource "${FULL_BACKUP_PATH}/cluster/clusterroles.yaml" "cluster roles"
restore_resource "${FULL_BACKUP_PATH}/cluster/clusterrolebindings.yaml" "cluster role bindings"

# Wait for namespaces to be ready
sleep 5

# Restore namespaces
echo -e "${YELLOW}📦 Restoring namespace resources...${NC}"
for namespace_dir in "${FULL_BACKUP_PATH}/namespaces"/*; do
    if [ -d "${namespace_dir}" ]; then
        namespace=$(basename "${namespace_dir}")
        echo -e "${YELLOW}📦 Processing namespace: ${namespace}${NC}"
        
        # Create namespace if it doesn't exist
        if ! kubectl get namespace "$namespace" >/dev/null 2>&1; then
            echo -e "${BLUE}📝 Creating namespace: ${namespace}${NC}"
            kubectl create namespace "$namespace" || echo -e "${YELLOW}⚠️  Namespace ${namespace} may already exist${NC}"
        fi
        
        # Wait for namespace to be ready
        wait_for_namespace "$namespace"
        
        # Restore resources in order
        restore_resource "${namespace_dir}/configmaps.yaml" "configmaps for ${namespace}"
        restore_resource "${namespace_dir}/secrets.yaml" "secrets for ${namespace}"
        restore_resource "${namespace_dir}/pvc.yaml" "PVCs for ${namespace}"
        restore_resource "${namespace_dir}/pv.yaml" "PVs for ${namespace}"
        restore_resource "${namespace_dir}/all-resources.yaml" "other resources for ${namespace}"
        restore_resource "${namespace_dir}/ingress.yaml" "ingress for ${namespace}"
        
        echo -e "${GREEN}✅ Namespace ${namespace} restored${NC}"
    fi
done

# Restore Helm releases
echo -e "${YELLOW}📊 Restoring Helm releases...${NC}"
if [ -f "${FULL_BACKUP_PATH}/helm/releases.yaml" ]; then
    echo -e "${BLUE}📄 Found Helm releases backup${NC}"
    
    # Extract release information and restore
    while IFS= read -r line; do
        if echo "$line" | grep -q "name:"; then
            release_name=$(echo "$line" | awk '{print $2}')
        elif echo "$line" | grep -q "namespace:"; then
            release_namespace=$(echo "$line" | awk '{print $2}')
        elif echo "$line" | grep -q "chart:"; then
            release_chart=$(echo "$line" | awk '{print $2}')
            
            if [ -n "$release_name" ] && [ -n "$release_namespace" ] && [ -n "$release_chart" ]; then
                echo -e "${BLUE}📦 Restoring Helm release: $release_name in $release_namespace${NC}"
                
                # Check if values file exists
                values_file="${FULL_BACKUP_PATH}/helm/${release_name}-values.yaml"
                if [ -f "$values_file" ]; then
                    echo -e "${BLUE}📄 Using values file: $values_file${NC}"
                    helm install "$release_name" "$release_chart" -n "$release_namespace" -f "$values_file" --create-namespace || \
                    helm upgrade "$release_name" "$release_chart" -n "$release_namespace" -f "$values_file" || \
                    echo -e "${YELLOW}⚠️  Could not restore Helm release: $release_name${NC}"
                else
                    echo -e "${YELLOW}⚠️  No values file found for $release_name, installing with default values${NC}"
                    helm install "$release_name" "$release_chart" -n "$release_namespace" --create-namespace || \
                    echo -e "${YELLOW}⚠️  Could not restore Helm release: $release_name${NC}"
                fi
                
                # Reset variables
                release_name=""
                release_namespace=""
                release_chart=""
            fi
        fi
    done < "${FULL_BACKUP_PATH}/helm/releases.yaml"
else
    echo -e "${YELLOW}⚠️  No Helm releases backup found${NC}"
fi

# Final status check
echo -e "${GREEN}✅ Restore process completed!${NC}"
echo -e "${BLUE}📊 Checking final status...${NC}"

echo -e "${YELLOW}📋 Namespace Status:${NC}"
kubectl get namespaces

echo -e "${YELLOW}📋 Pod Status:${NC}"
kubectl get pods --all-namespaces

echo -e "${YELLOW}📋 Helm Releases:${NC}"
helm list --all-namespaces

echo -e "${GREEN}🎉 Restore completed successfully!${NC}"
echo -e "${YELLOW}💡 Note: Some pods may take time to start. Check status with: kubectl get pods --all-namespaces${NC}"
EOF

    chmod +x "${FULL_BACKUP_PATH}/restore.sh"
}

# Main backup process
echo -e "${GREEN}📋 Backup Information:${NC}"
echo "Backup Directory: ${FULL_BACKUP_PATH}"
echo "Date: $(date)"
echo "Minikube Status: $(minikube status | head -1)"

# Backup cluster-wide resources
backup_cluster_resources

# Get all namespaces (excluding system ones)
NAMESPACES=$(kubectl get namespaces --no-headers -o custom-columns=NAME:.metadata.name | grep -v -E '^(kube-system|kube-public|kube-node-lease|default)$')

# Backup each namespace
for namespace in $NAMESPACES; do
    backup_namespace "${namespace}"
done

# Backup Helm releases
backup_helm_releases

# Create restore script
create_restore_script

# Create backup info file
cat > "${FULL_BACKUP_PATH}/backup-info.txt" << EOF
Minikube Backup Information
==========================
Backup Date: $(date)
Backup Name: ${BACKUP_NAME}
Minikube Version: $(minikube version --short)
Kubernetes Version: $(kubectl version --client -o short)

Namespaces Backed Up:
$(echo "${NAMESPACES}" | tr '\n' ' ')

Helm Releases:
$(helm list --all-namespaces -q | tr '\n' ' ')

To restore this backup:
1. Start minikube: minikube start
2. Run: ${FULL_BACKUP_PATH}/restore.sh ${BACKUP_NAME}
EOF

# Compress the backup
echo -e "${YELLOW}🗜️  Compressing backup...${NC}"
cd "${BACKUP_DIR}"
tar -czf "${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}"
rm -rf "${BACKUP_NAME}"

echo -e "${GREEN}✅ Backup completed successfully!${NC}"
echo -e "${GREEN}📁 Backup location: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz${NC}"
echo -e "${YELLOW}💡 To restore: tar -xzf ${BACKUP_NAME}.tar.gz && ./${BACKUP_NAME}/restore.sh ${BACKUP_NAME}${NC}"
