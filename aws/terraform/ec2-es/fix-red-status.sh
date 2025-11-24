#!/bin/bash

# Script to fix Elasticsearch RED status
# This script provides options to handle unassigned shards

ES_HOST="${1:-13.229.28.26:9200}"
ES_URL="http://${ES_HOST}"

echo "=========================================="
echo "Elasticsearch RED Status Fix Tool"
echo "=========================================="
echo "Target: $ES_URL"
echo ""

# Check current status
echo "Current cluster status:"
curl -s "$ES_URL/_cluster/health?pretty" | grep -E "status|unassigned_shards|active_shards_percent"
echo ""

# Get list of unassigned shards
echo "Getting list of unassigned shards..."
UNASSIGNED=$(curl -s "$ES_URL/_cat/shards?v&h=index,shard,prirep,state,unassigned.reason" | grep UNASSIGNED)

if [ -z "$UNASSIGNED" ]; then
    echo "No unassigned shards found!"
    exit 0
fi

echo "Found unassigned shards. Options:"
echo ""
echo "1. List all unassigned shards"
echo "2. Force allocate empty primary shards (DATA LOSS - use with caution)"
echo "3. Delete affected indices (DATA LOSS - use with caution)"
echo "4. Get detailed explanation for unassigned shards"
echo "5. Exit"
echo ""
read -p "Choose an option (1-5): " choice

case $choice in
    1)
        echo ""
        echo "Unassigned shards:"
        echo "$UNASSIGNED" | head -50
        echo ""
        echo "Total unassigned: $(echo "$UNASSIGNED" | wc -l)"
        ;;
    2)
        echo ""
        echo "WARNING: This will create empty shards and cause DATA LOSS!"
        read -p "Are you sure? Type 'yes' to continue: " confirm
        if [ "$confirm" != "yes" ]; then
            echo "Aborted."
            exit 1
        fi
        echo ""
        echo "Getting available nodes..."
        NODES=$(curl -s "$ES_URL/_cat/nodes?v&h=name" | tail -n +2)
        echo "Available nodes:"
        echo "$NODES"
        echo ""
        read -p "Enter node name to allocate shards to (or 'auto' for automatic): " node_name
        
        if [ "$node_name" = "auto" ]; then
            node_name=$(echo "$NODES" | head -1)
            echo "Using first available node: $node_name"
        fi
        
        echo ""
        echo "Force allocating empty primary shards..."
        echo "$UNASSIGNED" | grep " p " | while read line; do
            index=$(echo "$line" | awk '{print $1}')
            shard=$(echo "$line" | awk '{print $2}')
            echo "Allocating $index shard $shard to $node_name..."
            curl -s -X POST "$ES_URL/_cluster/reroute?pretty" \
                -H 'Content-Type: application/json' \
                -d "{
                    \"commands\": [
                        {
                            \"allocate_empty_primary\": {
                                \"index\": \"$index\",
                                \"shard\": $shard,
                                \"node\": \"$node_name\",
                                \"accept_data_loss\": true
                            }
                        }
                    ]
                }" | grep -E "acknowledged|error"
        done
        echo ""
        echo "Done. Checking cluster status..."
        sleep 2
        curl -s "$ES_URL/_cluster/health?pretty" | grep -E "status|unassigned_shards"
        ;;
    3)
        echo ""
        echo "WARNING: This will DELETE indices and cause DATA LOSS!"
        read -p "Are you sure? Type 'yes' to continue: " confirm
        if [ "$confirm" != "yes" ]; then
            echo "Aborted."
            exit 1
        fi
        echo ""
        echo "Getting list of affected indices..."
        AFFECTED_INDICES=$(echo "$UNASSIGNED" | awk '{print $1}' | sort -u)
        echo "Affected indices:"
        echo "$AFFECTED_INDICES"
        echo ""
        read -p "Enter index name to delete (or 'all' for all affected, or 'cancel' to abort): " index_to_delete
        
        if [ "$index_to_delete" = "cancel" ]; then
            echo "Aborted."
            exit 1
        elif [ "$index_to_delete" = "all" ]; then
            echo "Deleting all affected indices..."
            echo "$AFFECTED_INDICES" | while read index; do
                echo "Deleting $index..."
                curl -s -X DELETE "$ES_URL/$index?pretty" | grep -E "acknowledged|error"
            done
        else
            echo "Deleting $index_to_delete..."
            curl -s -X DELETE "$ES_URL/$index_to_delete?pretty" | grep -E "acknowledged|error"
        fi
        echo ""
        echo "Done. Checking cluster status..."
        sleep 2
        curl -s "$ES_URL/_cluster/health?pretty" | grep -E "status|unassigned_shards"
        ;;
    4)
        echo ""
        echo "Getting detailed explanation for unassigned shards..."
        curl -s "$ES_URL/_cluster/allocation/explain?pretty" | head -100
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

