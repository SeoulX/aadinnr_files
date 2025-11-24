#!/bin/bash

# Script to restore Elasticsearch indices from snapshot WITHOUT data loss
# This is the SAFE way to fix RED status

ES_HOST="${1:-13.229.28.26:9200}"
ES_URL="http://${ES_HOST}"
REPOSITORY="v4_s3_repository"

echo "=========================================="
echo "Elasticsearch Snapshot Restore Tool"
echo "=========================================="
echo "Target: $ES_URL"
echo "Repository: $REPOSITORY"
echo ""

# List available snapshots
echo "Available snapshots:"
curl -s "$ES_URL/_cat/snapshots/$REPOSITORY?v&h=id,status,indices,successful_shards,failed_shards" | head -15
echo ""

# Get most recent successful snapshot
LATEST_SUCCESS=$(curl -s "$ES_URL/_cat/snapshots/$REPOSITORY?v&h=id,status" | grep "SUCCESS" | tail -1 | awk '{print $1}')
echo "Most recent successful snapshot: $LATEST_SUCCESS"
echo ""

# Get list of affected indices (unassigned shards)
echo "Getting list of indices with unassigned shards..."
AFFECTED_INDICES=$(curl -s "$ES_URL/_cat/shards?v&h=index,shard,state" | grep UNASSIGNED | awk '{print $1}' | sort -u)
echo "Affected indices:"
echo "$AFFECTED_INDICES" | head -20
TOTAL_AFFECTED=$(echo "$AFFECTED_INDICES" | wc -l)
echo "... (Total: $TOTAL_AFFECTED indices)"
echo ""

echo "Options:"
echo "1. Check what indices are in the snapshot"
echo "2. Restore ALL affected indices from snapshot (recommended)"
echo "3. Restore specific index from snapshot"
echo "4. Restore specific indices from snapshot (comma-separated)"
echo "5. Exit"
echo ""
read -p "Choose an option (1-5): " choice

case $choice in
    1)
        echo ""
        echo "Checking indices in snapshot: $LATEST_SUCCESS"
        curl -s "$ES_URL/_snapshot/$REPOSITORY/$LATEST_SUCCESS?pretty" | grep -A 100 "indices" | head -50
        ;;
    2)
        echo ""
        echo "WARNING: This will restore ALL affected indices from snapshot."
        echo "This may overwrite existing data in those indices."
        read -p "Are you sure? Type 'yes' to continue: " confirm
        if [ "$confirm" != "yes" ]; then
            echo "Aborted."
            exit 1
        fi
        
        echo ""
        echo "Restoring affected indices from snapshot: $LATEST_SUCCESS"
        echo "This may take a while..."
        
        # Convert indices list to JSON array
        INDICES_JSON=$(echo "$AFFECTED_INDICES" | sed 's/^/"/;s/$/"/' | tr '\n' ',' | sed 's/,$//')
        
        curl -X POST "$ES_URL/_snapshot/$REPOSITORY/$LATEST_SUCCESS/_restore?pretty" \
            -H 'Content-Type: application/json' \
            -d "{
                \"indices\": [$INDICES_JSON],
                \"ignore_unavailable\": true,
                \"include_global_state\": false
            }"
        
        echo ""
        echo "Restore initiated. Monitor progress with:"
        echo "curl -X GET \"$ES_URL/_cat/recovery?v\""
        ;;
    3)
        echo ""
        read -p "Enter index name to restore: " index_name
        echo ""
        echo "Restoring $index_name from snapshot: $LATEST_SUCCESS"
        
        curl -X POST "$ES_URL/_snapshot/$REPOSITORY/$LATEST_SUCCESS/_restore?pretty" \
            -H 'Content-Type: application/json' \
            -d "{
                \"indices\": \"$index_name\",
                \"ignore_unavailable\": true,
                \"include_global_state\": false
            }"
        
        echo ""
        echo "Restore initiated. Monitor progress with:"
        echo "curl -X GET \"$ES_URL/_cat/recovery?v\""
        ;;
    4)
        echo ""
        read -p "Enter comma-separated list of indices to restore: " indices_list
        echo ""
        echo "Restoring indices from snapshot: $LATEST_SUCCESS"
        
        # Convert comma-separated to JSON array
        INDICES_JSON=$(echo "$indices_list" | sed 's/,/","/g' | sed 's/^/"/;s/$/"/')
        
        curl -X POST "$ES_URL/_snapshot/$REPOSITORY/$LATEST_SUCCESS/_restore?pretty" \
            -H 'Content-Type: application/json' \
            -d "{
                \"indices\": [$INDICES_JSON],
                \"ignore_unavailable\": true,
                \"include_global_state\": false
            }"
        
        echo ""
        echo "Restore initiated. Monitor progress with:"
        echo "curl -X GET \"$ES_URL/_cat/recovery?v\""
        ;;
    5)
        echo "Exiting."
        exit 0
        ;;
    *)
        echo "Invalid option."
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo "After restore completes, check status:"
echo "curl -X GET \"$ES_URL/_cluster/health?pretty\""
echo "=========================================="

