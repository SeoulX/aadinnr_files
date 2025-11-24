#!/bin/bash

# Script to check configuration of a working node (es0-es6)
# to compare with Terraform nodes (es7-es10)

WORKING_NODE_IP="${1:-10.0.3.9}"  # Default to ip-10-0-3-9 (working node)
SSH_KEY="${2:-../terraform_key_pair.cer}"  # Adjust path as needed

echo "=========================================="
echo "Checking Working Node Configuration"
echo "=========================================="
echo "Node IP: $WORKING_NODE_IP"
echo ""

if [ ! -f "$SSH_KEY" ]; then
    echo "⚠️  SSH key not found at: $SSH_KEY"
    echo "   Please provide path to SSH key as second argument"
    echo "   Usage: $0 <node_ip> <ssh_key_path>"
    exit 1
fi

echo "Connecting to node..."
ssh -o IdentitiesOnly=yes -i "$SSH_KEY" -o StrictHostKeyChecking=no ubuntu@"$WORKING_NODE_IP" << 'EOF'
  echo "=== NODE INFORMATION ==="
  echo "Hostname: $(hostname)"
  echo "IP: $(hostname -I | awk '{print $1}')"
  echo ""
  
  echo "=== DOCKER CONTAINER ==="
  CONTAINER=$(docker ps --format "{{.Names}}" | grep -E "ip-10-0-3|elasticsearch" | head -1)
  if [ -n "$CONTAINER" ]; then
    echo "Container: $CONTAINER"
    echo ""
    
    echo "=== ELASTICSEARCH PLUGINS ==="
    echo "Installed plugins:"
    docker exec "$CONTAINER" bin/elasticsearch-plugin list 2>/dev/null || echo "Cannot list plugins"
    echo ""
    
    echo "=== CHECKING FOR S3 PLUGIN ==="
    if docker exec "$CONTAINER" bin/elasticsearch-plugin list 2>/dev/null | grep -q "repository-s3"; then
      echo "✓ S3 plugin is INSTALLED"
    else
      echo "✗ S3 plugin is NOT installed"
    fi
    echo ""
    
    echo "=== ELASTICSEARCH VERSION ==="
    docker exec "$CONTAINER" bin/elasticsearch --version 2>/dev/null || echo "Cannot get version"
    echo ""
    
    echo "=== DOCKER IMAGE ==="
    docker inspect "$CONTAINER" --format='{{.Config.Image}}' 2>/dev/null || echo "Cannot get image"
    echo ""
  else
    echo "✗ No Elasticsearch container found"
  fi
  
  echo "=== IAM ROLE (from metadata) ==="
  IAM_ROLE=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/ 2>/dev/null)
  if [ -n "$IAM_ROLE" ]; then
    echo "IAM Role: $IAM_ROLE"
    echo ""
    echo "IAM Role details:"
    curl -s http://169.254.169.254/latest/meta-data/iam/info 2>/dev/null | head -10
  else
    echo "✗ No IAM role attached"
  fi
  echo ""
  
  echo "=== DOCKER COMPOSE CONFIG ==="
  if [ -f "/home/ubuntu/docker-compose.yaml" ]; then
    echo "docker-compose.yaml exists"
    echo "Elasticsearch image:"
    grep -i "image:" /home/ubuntu/docker-compose.yaml | head -1
  else
    echo "docker-compose.yaml not found"
  fi
  echo ""
  
  echo "=== SYSTEM INFO ==="
  echo "OS: $(lsb_release -d 2>/dev/null | cut -f2)"
  echo "Docker version: $(docker --version 2>/dev/null)"
  echo ""
EOF

echo ""
echo "=========================================="
echo "Comparison with Terraform nodes:"
echo "=========================================="
echo ""
echo "Terraform nodes (es7-es10) use:"
echo "  - Image: docker.elastic.co/elasticsearch/elasticsearch:7.17.7"
echo "  - No S3 plugin installation in user_data.sh"
echo "  - No IAM role in main.tf"
echo ""
echo "Check above to see what es6 has that es7-es10 are missing!"


