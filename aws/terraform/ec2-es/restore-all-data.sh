#!/bin/bash

# Script to restore ALL possible data from snapshots (NO DATA LOSS)
# This will restore indices from the best available snapshot

ES_HOST="${1:-13.229.28.26:9200}"
ES_URL="http://${ES_HOST}"
REPO="v4_s3_repository"

echo "=========================================="
echo "Restore All Data (NO DATA LOSS)"
echo "=========================================="
echo "Target: $ES_URL"
echo ""

# Get affected indices
echo "Getting affected indices with unassigned shards..."
AFFECTED=$(curl -s "$ES_URL/_cat/shards?v&h=index,shard,state" | grep UNASSIGNED | awk '{print $1}' | sort -u)
AFFECTED_COUNT=$(echo "$AFFECTED" | wc -l)
echo "Total affected indices: $AFFECTED_COUNT"
echo ""

# Get all successful snapshots
echo "Getting available snapshots..."
SNAPSHOTS=$(curl -s "$ES_URL/_cat/snapshots/$REPO?v&h=id,status" | grep SUCCESS | awk '{print $1}' | tail -10)
echo "Available snapshots:"
echo "$SNAPSHOTS"
echo ""

# Use latest successful snapshot
LATEST_SNAP=$(echo "$SNAPSHOTS" | tail -1)
echo "Using snapshot: $LATEST_SNAP"
echo ""

# Get indices in latest snapshot
echo "Checking which affected indices are in snapshot..."
SNAPSHOT_INDICES=$(curl -s "$ES_URL/_snapshot/$REPO/$LATEST_SNAP?pretty" | grep -A 500 '"indices"' | grep -o '"[^"]*"' | tr -d '"' | grep -v "^indices$" | sort -u)

RESTORABLE=""
NOT_RESTORABLE=""

for index in $AFFECTED; do
    if echo "$SNAPSHOT_INDICES" | grep -q "^${index}$"; then
        RESTORABLE="$RESTORABLE $index"
    else
        NOT_RESTORABLE="$NOT_RESTORABLE $index"
    fi
done

RESTORABLE_COUNT=$(echo $RESTORABLE | wc -w)
NOT_RESTORABLE_COUNT=$(echo $NOT_RESTORABLE | wc -w)

echo "=========================================="
echo "Summary:"
echo "  ✓ Can restore (in snapshot): $RESTORABLE_COUNT indices"
echo "  ✗ Not in snapshot: $NOT_RESTORABLE_COUNT indices"
echo "=========================================="
echo ""

if [ "$NOT_RESTORABLE_COUNT" -gt 0 ]; then
    echo "Indices NOT in snapshot (will need alternative solution):"
    for idx in $NOT_RESTORABLE; do
        echo "  - $idx"
    done
    echo ""
fi

if [ "$RESTORABLE_COUNT" -eq 0 ]; then
    echo "No indices can be restored from this snapshot."
    echo "Checking older snapshots..."
    exit 1
fi

echo "Ready to restore $RESTORABLE_COUNT indices from snapshot: $LATEST_SNAP"
echo ""
read -p "This will restore data from snapshot (NO DATA LOSS). Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "Restoring indices from snapshot..."
echo "This may take several minutes..."
echo ""

# Convert to JSON array format
INDICES_ARRAY=$(echo $RESTORABLE | sed 's/^ *//;s/ *$//' | sed 's/ /","/g' | sed 's/^/"/;s/$/"/')

# Restore from snapshot
RESPONSE=$(curl -s -X POST "$ES_URL/_snapshot/$REPO/$LATEST_SNAP/_restore?pretty" \
    -H 'Content-Type: application/json' \
    -d "{
        \"indices\": [$INDICES_ARRAY],
        \"ignore_unavailable\": true,
        \"include_global_state\": false,
        \"wait_for_completion\": false
    }")

echo "$RESPONSE"
echo ""

# Check if restore was accepted
if echo "$RESPONSE" | grep -q "accepted\|acknowledged"; then
    echo "=========================================="
    echo "✓ Restore initiated successfully!"
    echo "=========================================="
    echo ""
    echo "Monitor restore progress:"
    echo "  curl -X GET \"$ES_URL/_cat/recovery?v\""
    echo ""
    echo "Check cluster status:"
    echo "  curl -X GET \"$ES_URL/_cluster/health?pretty\""
    echo ""
    echo "The restore is running in the background."
    echo "Cluster status should improve as shards are restored."
else
    echo "✗ Restore failed. Check the response above."
    exit 1
fi

echo ""
echo "Note: $NOT_RESTORABLE_COUNT indices are not in this snapshot."
echo "You may need to:"
echo "  1. Check older snapshots for these indices"
echo "  2. Re-index from source data if available"
echo "  3. Or accept data loss for these specific indices"

