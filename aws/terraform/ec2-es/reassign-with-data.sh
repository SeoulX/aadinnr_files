#!/bin/bash

# Script to REASSIGN shards WITH DATA (not empty) by restoring from snapshots
# This is the ONLY way to reassign shards with actual data when nodes left
#
# SOLUTION: This script closes indices before restore, which allows the restore
# to overwrite existing indices. Without closing, you get:
#   "cannot restore index [...] because an open index with same name already exists"
#
# Process:
#   1. Identify indices with unassigned shards
#   2. Check which are available in latest snapshot
#   3. Close those indices (required for restore)
#   4. Restore from snapshot (reassigns shards WITH data)
#   5. Indices will be automatically reopened after restore completes

ES_HOST="${1:-13.229.28.26:9200}"
ES_URL="http://${ES_HOST}"
REPO="v4_s3_repository"

echo "=========================================="
echo "Re-assign Shards WITH DATA (Not Empty)"
echo "=========================================="
echo "Target: $ES_URL"
echo ""
echo "NOTE: The only way to reassign shards WITH data is to restore from snapshots."
echo "Shard data does not exist on current nodes (nodes left with the data)."
echo ""

# Get affected indices
echo "Getting indices with unassigned shards..."
AFFECTED=$(curl -s "$ES_URL/_cat/shards?v&h=index,shard,state" | grep UNASSIGNED | awk '{print $1}' | sort -u)
AFFECTED_COUNT=$(echo "$AFFECTED" | wc -l)
echo "Total affected indices: $AFFECTED_COUNT"
echo ""

# Get latest successful snapshot
LATEST_SNAP=$(curl -s "$ES_URL/_cat/snapshots/$REPO?v&h=id,status" | grep SUCCESS | tail -1 | awk '{print $1}')
echo "Latest successful snapshot: $LATEST_SNAP"
echo ""

# Check which indices are in snapshot
echo "Checking which indices can be restored (reassigned WITH data)..."
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
echo "Results:"
echo "  ✓ Can reassign WITH data (in snapshot): $RESTORABLE_COUNT indices"
echo "  ✗ Cannot reassign (not in snapshot): $NOT_RESTORABLE_COUNT indices"
echo "=========================================="
echo ""

if [ "$RESTORABLE_COUNT" -eq 0 ]; then
    echo "No indices can be restored from this snapshot."
    echo "Checking older snapshots..."
    exit 1
fi

echo "Ready to REASSIGN $RESTORABLE_COUNT shards WITH DATA from snapshot."
echo "This will:"
echo "  1. Restore shard data from snapshot"
echo "  2. Reassign shards to available nodes"
echo "  3. Fix RED status WITHOUT data loss"
echo ""
read -p "Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "Step 1: Closing indices before restore..."
echo "  (Required to allow restore to overwrite existing indices)"
CLOSED_COUNT=0
for index in $RESTORABLE; do
    # Remove leading/trailing spaces
    index=$(echo "$index" | xargs)
    if [ -z "$index" ]; then
        continue
    fi
    
    STATUS=$(curl -s "$ES_URL/_cat/indices/$index?v&h=status" 2>/dev/null | tail -1)
    if [ "$STATUS" = "open" ]; then
        curl -s -X POST "$ES_URL/$index/_close" > /dev/null 2>&1
        CLOSED_COUNT=$((CLOSED_COUNT + 1))
        if [ $((CLOSED_COUNT % 20)) -eq 0 ]; then
            echo "  Closed $CLOSED_COUNT indices..."
        fi
    fi
done
echo "  ✓ Closed $CLOSED_COUNT indices"
echo ""

echo "Step 2: Waiting 3 seconds for indices to close..."
sleep 3
echo ""

echo "Step 3: Restoring indices from snapshot (reassigning shards WITH data)..."
echo "  Snapshot: $LATEST_SNAP"
echo "  This will take several minutes..."
echo ""

# Convert to JSON array
INDICES_ARRAY=$(echo $RESTORABLE | sed 's/^ *//;s/ *$//' | sed 's/ /","/g' | sed 's/^/"/;s/$/"/')

# Restore - this will reassign shards WITH actual data
RESPONSE=$(curl -s -X POST "$ES_URL/_snapshot/$REPO/$LATEST_SNAP/_restore?pretty" \
    -H 'Content-Type: application/json' \
    -d "{
        \"indices\": [$INDICES_ARRAY],
        \"ignore_unavailable\": true,
        \"include_global_state\": false
    }")

echo "$RESPONSE"
echo ""

if echo "$RESPONSE" | grep -q "accepted\|acknowledged"; then
    echo "=========================================="
    echo "✓ Restore initiated - Shards will be reassigned WITH DATA"
    echo "=========================================="
    echo ""
    echo "This process will:"
    echo "  - Restore shard data from snapshot"
    echo "  - Assign shards to available nodes"
    echo "  - Automatically reopen indices after restore completes"
    echo "  - Fix RED status gradually as shards are restored"
    echo ""
    echo "Current status:"
    curl -s "$ES_URL/_cluster/health?pretty" | grep -E "status|active_shards|unassigned|initializing|active_shards_percent"
    echo ""
    
    # Check for active recoveries
    sleep 2
    RECOVERY_COUNT=$(curl -s "$ES_URL/_cat/recovery?v&active_only=true" | wc -l)
    RECOVERY_COUNT=$((RECOVERY_COUNT - 1))
    if [ "$RECOVERY_COUNT" -gt 0 ]; then
        echo "✓ Active recovery operations: $RECOVERY_COUNT"
        echo ""
        echo "Top 10 active recoveries:"
        curl -s "$ES_URL/_cat/recovery?v&h=index,shard,type,stage,bytes_percent,time&active_only=true" | head -11
        echo ""
    fi
    
    echo "Monitor progress:"
    echo "  ./monitor-restore-progress.sh"
    echo ""
    echo "Or manually:"
    echo "  curl -X GET \"$ES_URL/_cat/recovery?v&active_only=true\""
    echo "  curl -X GET \"$ES_URL/_cluster/health?pretty\""
else
    echo "✗ Restore failed. Check the response above."
    exit 1
fi

if [ "$NOT_RESTORABLE_COUNT" -gt 0 ]; then
    echo ""
    echo "=========================================="
    echo "Note: $NOT_RESTORABLE_COUNT indices are NOT in snapshot"
    echo "=========================================="
    echo "These indices cannot be reassigned with data:"
    for idx in $NOT_RESTORABLE; do
        echo "  - $idx"
    done
    echo ""
    echo "Options for these indices:"
    echo "  1. Check older snapshots"
    echo "  2. Re-index from source data"
    echo "  3. Accept data loss (force allocate empty shards)"
fi

