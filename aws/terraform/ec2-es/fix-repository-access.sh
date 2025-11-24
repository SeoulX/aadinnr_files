#!/bin/bash

# Script to fix S3 repository access on all Elasticsearch nodes
# This re-registers the repository so all nodes can access it

ES_HOST="${1:-13.229.28.26:9200}"
ES_URL="http://${ES_HOST}"
REPO="v4_s3_repository"

echo "=========================================="
echo "Fix S3 Repository Access"
echo "=========================================="
echo "Target: $ES_URL"
echo "Repository: $REPO"
echo ""

echo "Step 1: Checking current repository status..."
CURRENT_REPO=$(curl -s "$ES_URL/_snapshot/$REPO?pretty")
echo "$CURRENT_REPO"
echo ""

# Extract settings
BUCKET=$(echo "$CURRENT_REPO" | grep '"bucket"' | awk -F'"' '{print $4}')
REGION=$(echo "$CURRENT_REPO" | grep '"region"' | awk -F'"' '{print $4}')
BASE_PATH=$(echo "$CURRENT_REPO" | grep '"base_path"' | awk -F'"' '{print $4}')

echo "Repository settings:"
echo "  Bucket: $BUCKET"
echo "  Region: $REGION"
echo "  Base path: $BASE_PATH"
echo ""

echo "Step 2: Verifying repository (this will show which nodes can't access it)..."
VERIFY_RESULT=$(curl -s -X POST "$ES_URL/_snapshot/$REPO/_verify?pretty")
echo "$VERIFY_RESULT" | head -30
echo ""

echo "Step 3: Re-registering repository (this should propagate to all nodes)..."
echo ""

# Delete existing repository
echo "Deleting existing repository..."
DELETE_RESULT=$(curl -s -X DELETE "$ES_URL/_snapshot/$REPO?pretty")
echo "$DELETE_RESULT"
echo ""

echo "Waiting 2 seconds..."
sleep 2

# Re-register repository
echo "Re-registering repository with same settings..."
REGISTER_RESULT=$(curl -s -X PUT "$ES_URL/_snapshot/$REPO?pretty" \
  -H 'Content-Type: application/json' \
  -d "{
    \"type\": \"s3\",
    \"settings\": {
      \"bucket\": \"$BUCKET\",
      \"region\": \"$REGION\",
      \"base_path\": \"$BASE_PATH\"
    }
  }")

echo "$REGISTER_RESULT"
echo ""

echo "Waiting 3 seconds for propagation..."
sleep 3

echo "Step 4: Verifying repository on all nodes..."
VERIFY_AFTER=$(curl -s -X POST "$ES_URL/_snapshot/$REPO/_verify?pretty")
echo "$VERIFY_AFTER" | head -40
echo ""

# Check if verification succeeded
if echo "$VERIFY_AFTER" | grep -q "nodes"; then
    NODES_OK=$(echo "$VERIFY_AFTER" | grep -c "ip-")
    echo "✓ Repository accessible on $NODES_OK nodes"
    
    if echo "$VERIFY_AFTER" | grep -q "RepositoryMissingException"; then
        echo "⚠️  Some nodes still can't access repository"
        echo "   This may require:"
        echo "   1. IAM role with S3 permissions on EC2 instances"
        echo "   2. S3 repository plugin installed on all nodes"
        echo "   3. Network access to S3"
    else
        echo "✓ Repository accessible on all nodes!"
    fi
else
    echo "✗ Verification failed - check error above"
fi

echo ""
echo "Step 5: Testing snapshot access..."
SNAPSHOTS=$(curl -s "$ES_URL/_snapshot/$REPO/_all?pretty" 2>/dev/null | head -20)
if [ -n "$SNAPSHOTS" ]; then
    echo "✓ Can list snapshots"
    echo "$SNAPSHOTS" | head -10
else
    echo "✗ Cannot list snapshots"
fi

echo ""
echo "=========================================="
echo "Next steps:"
echo "1. If repository is now accessible, retry restore"
echo "2. If still failing, check IAM roles and S3 plugin"
echo "=========================================="


