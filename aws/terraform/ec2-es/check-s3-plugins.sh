#!/bin/bash

# Script to check S3 plugin installation on all Elasticsearch nodes
# Uses the same pattern as fix-permissions.sh

SSH_KEY="$HOME/Downloads/terraform_key_pair.cer"

# Excluded nodes (4 nodes that need S3 plugin)
EXCLUDED_INSTANCES=(
  "ec2-18-142-227-181.ap-southeast-1.compute.amazonaws.com"  # ip-10-0-3-23
  "ec2-13-215-206-195.ap-southeast-1.compute.amazonaws.com"  # ip-10-0-3-88
  "ec2-54-151-197-160.ap-southeast-1.compute.amazonaws.com"  # ip-10-0-3-167
  "ec2-54-251-18-55.ap-southeast-1.compute.amazonaws.com"   # ip-10-0-3-114
)

echo "=========================================="
echo "Checking S3 Plugin on Excluded Nodes"
echo "=========================================="
echo ""

for HOST in "${EXCLUDED_INSTANCES[@]}"; do
  echo "=========================================="
  echo "Checking: $HOST"
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
    
    echo "2. Checking installed plugins..."
    PLUGINS=$(docker exec "$CONTAINER" bin/elasticsearch-plugin list 2>/dev/null)
    
    if [ $? -eq 0 ]; then
      echo "   Installed plugins:"
      echo "$PLUGINS" | sed 's/^/     /'
      echo ""
      
      if echo "$PLUGINS" | grep -q "repository-s3"; then
        echo "   ✓ S3 plugin is INSTALLED"
      else
        echo "   ✗ S3 plugin is NOT installed"
      fi
    else
      echo "   ✗ Cannot list plugins (container may not be running)"
    fi
    
    echo ""
    echo "3. Elasticsearch version:"
    VERSION=$(docker exec "$CONTAINER" bin/elasticsearch --version 2>/dev/null | head -1)
    echo "   $VERSION"
    echo ""
    
    echo "4. Docker image:"
    IMAGE=$(docker inspect "$CONTAINER" --format='{{.Config.Image}}' 2>/dev/null)
    echo "   $IMAGE"
    echo ""
EOF

  if [ $? -eq 0 ]; then
    echo "✓ Checked $HOST"
  else
    echo "✗ Failed to check $HOST"
  fi
  echo ""
done

echo "=========================================="
echo "Checking S3 Plugin on Working Nodes (Sample)"
echo "=========================================="
echo ""

# Check a couple of working nodes for comparison
WORKING_INSTANCES=(
  "ec2-$(curl -s http://13.229.28.26:9200/_cat/nodes?h=ip | grep "10.0.3.9" | head -1 | awk '{print $1}').ap-southeast-1.compute.amazonaws.com"
)

# Actually, let's just check one working node if we can find its DNS
echo "To check working nodes, we need their public DNS names"
echo "Or we can check via Elasticsearch API which nodes have the plugin"
echo ""

echo "=========================================="
echo "Summary"
echo "=========================================="
echo ""
echo "If excluded nodes show '✗ S3 plugin is NOT installed',"
echo "then that's the problem - need to install it."
echo ""


