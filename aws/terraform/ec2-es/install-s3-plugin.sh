#!/bin/bash

# Script to install S3 repository plugin on excluded nodes
# This fixes RepositoryMissingException on the 4 Terraform nodes

# SSH key path - adjust if your key is in a different location
SSH_KEY="${1:-$HOME/Downloads/terraform_key_pair.cer}"

if [ ! -f "$SSH_KEY" ]; then
    echo "⚠️  SSH key not found: $SSH_KEY"
    echo "Usage: $0 [ssh_key_path]"
    echo "Default: $HOME/Downloads/terraform_key_pair.cer"
    exit 1
fi

# Instance DNS names (4 excluded nodes)
INSTANCES=(
  "ec2-18-142-227-181.ap-southeast-1.compute.amazonaws.com"  # ip-10-0-3-23
  "ec2-13-215-206-195.ap-southeast-1.compute.amazonaws.com"  # ip-10-0-3-88
  "ec2-54-151-197-160.ap-southeast-1.compute.amazonaws.com"  # ip-10-0-3-167
  "ec2-54-251-18-55.ap-southeast-1.compute.amazonaws.com"   # ip-10-0-3-114
)

echo "=========================================="
echo "Install S3 Repository Plugin"
echo "=========================================="
echo "Installing on ${#INSTANCES[@]} excluded nodes"
echo ""

for HOST in "${INSTANCES[@]}"; do
  echo ""
  echo "=========================================="
  echo "Processing: $HOST"
  echo "=========================================="
  
  ssh -o IdentitiesOnly=yes -i "$SSH_KEY" -o StrictHostKeyChecking=no ubuntu@"$HOST" << 'EOF'
      echo "1. Finding Elasticsearch container..."
      CONTAINER=$(docker ps --format "{{.Names}}" | grep -E "ip-10-0-3|elasticsearch" | head -1)
      
      if [ -z "$CONTAINER" ]; then
        echo "✗ No Elasticsearch container found"
        exit 1
      fi
      
      echo "   Container: $CONTAINER"
      echo ""
      
      echo "2. Checking if S3 plugin is already installed..."
      if docker exec "$CONTAINER" bin/elasticsearch-plugin list 2>/dev/null | grep -q "repository-s3"; then
        echo "   ✓ S3 plugin already installed"
        echo "   Skipping installation"
        exit 0
      fi
      
      echo "   ✗ S3 plugin not found - installing..."
      echo ""
      
      echo "3. Installing repository-s3 plugin..."
      echo "   This may take a few minutes..."
      
      # Install plugin (non-interactive)
      INSTALL_OUTPUT=$(docker exec "$CONTAINER" bin/elasticsearch-plugin install --batch repository-s3 2>&1)
      INSTALL_EXIT=$?
      
      if [ $INSTALL_EXIT -eq 0 ]; then
        echo "   ✓ Plugin installed successfully"
      else
        echo "   ✗ Plugin installation failed:"
        echo "$INSTALL_OUTPUT" | tail -10
        exit 1
      fi
      
      echo ""
      echo "4. Verifying installation..."
      if docker exec "$CONTAINER" bin/elasticsearch-plugin list 2>/dev/null | grep -q "repository-s3"; then
        echo "   ✓ S3 plugin verified"
      else
        echo "   ✗ S3 plugin not found after installation"
        exit 1
      fi
      
      echo ""
      echo "5. Restarting Elasticsearch container..."
      cd /home/ubuntu
      export HOSTNAME=$(hostname)
      export HOST_IP=$(hostname -I | awk '{print $1}')
      docker compose restart
      
      echo ""
      echo "6. Waiting for Elasticsearch to start (10 seconds)..."
      sleep 10
      
      echo ""
      echo "7. Checking if Elasticsearch is running..."
      if docker ps | grep -q "$CONTAINER"; then
        echo "   ✓ Container is running"
      else
        echo "   ⚠️  Container may have issues - check logs"
      fi
      
      echo ""
      echo "✓ Installation complete on $(hostname)"
EOF

  if [ $? -eq 0 ]; then
    echo "✓ Successfully installed S3 plugin on $HOST"
  else
    echo "✗ Failed to install S3 plugin on $HOST"
  fi
done

echo "=========================================="
echo "Installation Summary"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Wait a few minutes for all containers to restart"
echo "2. Verify repository access:"
echo "   curl -X POST 'http://13.229.28.26:9200/_snapshot/v4_s3_repository/_verify?pretty'"
echo "3. If verification passes, retry restore"
echo ""

