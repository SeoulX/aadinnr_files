#!/bin/bash

# Script to monitor Elasticsearch restore progress simultaneously
# Shows all key metrics in one view and detects if recoveries stop/pause

ES_HOST="${1:-13.229.28.26:9200}"
ES_URL="http://${ES_HOST}"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Track previous state
PREV_RECOVERY_COUNT=0
PREV_UNASSIGNED=0
ITERATION=0

clear
echo "=========================================="
echo "Elasticsearch Restore Progress Monitor"
echo "=========================================="
echo "Target: $ES_URL"
echo "Press Ctrl+C to exit"
echo "=========================================="
echo ""

while true; do
    ITERATION=$((ITERATION + 1))
    
    # Get cluster health
    HEALTH=$(curl -s "$ES_URL/_cluster/health?pretty")
    STATUS=$(echo "$HEALTH" | grep '"status"' | awk '{print $3}' | tr -d '",')
    ACTIVE_SHARDS=$(echo "$HEALTH" | grep '"active_shards"' | awk '{print $3}' | tr -d ',')
    UNASSIGNED=$(echo "$HEALTH" | grep '"unassigned_shards"' | awk '{print $3}' | tr -d ',')
    ACTIVE_PERCENT=$(echo "$HEALTH" | grep '"active_shards_percent_as_number"' | awk '{print $3}' | tr -d ',')
    INITIALIZING=$(echo "$HEALTH" | grep '"initializing_shards"' | awk '{print $3}' | tr -d ',')
    
    # Get recovery count
    RECOVERY_COUNT=$(curl -s "$ES_URL/_cat/recovery?v&active_only=true" | wc -l)
    RECOVERY_COUNT=$((RECOVERY_COUNT - 1))  # Subtract header
    
    # Get unassigned shards breakdown by reason
    UNASSIGNED_BREAKDOWN=$(curl -s "$ES_URL/_cat/shards?v&h=index,shard,state,unassigned.reason" 2>/dev/null | grep "UNASSIGNED" | awk '{print $4}' | sort | uniq -c | sort -rn)
    
    # Detect if recoveries stopped/paused
    RECOVERY_STOPPED=false
    RECOVERY_PAUSED=false
    if [ "$RECOVERY_COUNT" -eq 0 ] && [ "$PREV_RECOVERY_COUNT" -gt 0 ]; then
        RECOVERY_STOPPED=true
    fi
    if [ "$RECOVERY_COUNT" -eq 0 ] && [ "$UNASSIGNED" -gt 0 ] && [ "$INITIALIZING" -eq 0 ]; then
        RECOVERY_PAUSED=true
    fi
    
    # Check if progress stalled
    PROGRESS_STALLED=false
    if [ "$UNASSIGNED" -eq "$PREV_UNASSIGNED" ] && [ "$ITERATION" -gt 2 ] && [ "$RECOVERY_COUNT" -eq 0 ]; then
        PROGRESS_STALLED=true
    fi
    
    # Clear screen and show status
    clear
    echo "=========================================="
    echo "Elasticsearch Restore Progress Monitor"
    echo "=========================================="
    echo "Time: $(date '+%Y-%m-%d %H:%M:%S') | Iteration: $ITERATION"
    echo ""
    
    # Status with color
    if [ "$STATUS" = "green" ]; then
        echo -e "Cluster Status: ${GREEN}$STATUS${NC}"
    elif [ "$STATUS" = "yellow" ]; then
        echo -e "Cluster Status: ${YELLOW}$STATUS${NC}"
    else
        echo -e "Cluster Status: ${RED}$STATUS${NC}"
    fi
    
    echo "----------------------------------------"
    echo "Shards:"
    echo "  Active:           $ACTIVE_SHARDS"
    echo "  Unassigned:       $UNASSIGNED"
    echo "  Initializing:     $INITIALIZING"
    echo "  Active Percent:   ${ACTIVE_PERCENT}%"
    echo ""
    
    # Recovery status with warnings
    echo "Recovery:"
    if [ "$RECOVERY_COUNT" -gt 0 ]; then
        echo -e "  Active Operations: ${GREEN}$RECOVERY_COUNT${NC} ✓"
    else
        if [ "$RECOVERY_STOPPED" = true ]; then
            echo -e "  Active Operations: ${YELLOW}0 (STOPPED)${NC} ⚠️"
        elif [ "$RECOVERY_PAUSED" = true ]; then
            echo -e "  Active Operations: ${YELLOW}0 (PAUSED)${NC} ⚠️"
        else
            echo -e "  Active Operations: 0"
        fi
    fi
    echo ""
    
    # Show why recoveries paused/stopped
    if [ "$RECOVERY_PAUSED" = true ] || [ "$PROGRESS_STALLED" = true ]; then
        echo -e "${YELLOW}⚠️  RECOVERY PAUSED/STALLED - Reasons:${NC}"
        echo "----------------------------------------"
        if [ -n "$UNASSIGNED_BREAKDOWN" ]; then
            echo "$UNASSIGNED_BREAKDOWN" | while read count reason; do
                case "$reason" in
                    "INDEX_CLOSED")
                        echo -e "  ${CYAN}$count shards${NC}: INDEX_CLOSED - Indices need to be opened"
                        ;;
                    "NODE_LEFT")
                        echo -e "  ${RED}$count shards${NC}: NODE_LEFT - Data not in snapshot (may need re-index)"
                        ;;
                    "ALLOCATION_FAILED")
                        echo -e "  ${RED}$count shards${NC}: ALLOCATION_FAILED - Check node capacity/permissions"
                        ;;
                    "MANUAL_ALLOCATION")
                        echo -e "  ${YELLOW}$count shards${NC}: MANUAL_ALLOCATION - Requires manual allocation"
                        ;;
                    "EXISTING_INDEX_RESTORED")
                        echo -e "  ${YELLOW}$count shards${NC}: EXISTING_INDEX_RESTORED - Restored but not assigned (open indices)"
                        ;;
                    *)
                        echo -e "  ${YELLOW}$count shards${NC}: $reason"
                        ;;
                esac
            done
        else
            echo "  No unassigned shards found"
        fi
        echo ""
    fi
    
    # Show top recovery operations
    if [ "$RECOVERY_COUNT" -gt 0 ]; then
        echo "Top Recovery Operations:"
        echo "----------------------------------------"
        curl -s "$ES_URL/_cat/recovery?v&h=index,shard,type,stage,bytes_percent,time&active_only=true" | head -10
        echo ""
    fi
    
    # Progress bar for active shards percent
    PERCENT_INT=$(echo "$ACTIVE_PERCENT" | cut -d. -f1)
    BAR_LENGTH=$((PERCENT_INT / 2))
    BAR=""
    for i in $(seq 1 50); do
        if [ $i -le $BAR_LENGTH ]; then
            BAR="${BAR}█"
        else
            BAR="${BAR}░"
        fi
    done
    echo "Progress: [$BAR] ${ACTIVE_PERCENT}%"
    
    # Show change since last check
    if [ "$ITERATION" -gt 1 ]; then
        UNASSIGNED_DELTA=$((PREV_UNASSIGNED - UNASSIGNED))
        if [ "$UNASSIGNED_DELTA" -gt 0 ]; then
            echo -e "${GREEN}✓ Recovered $UNASSIGNED_DELTA shards since last check${NC}"
        elif [ "$UNASSIGNED_DELTA" -lt 0 ]; then
            echo -e "${RED}⚠️  Unassigned increased by $((UNASSIGNED_DELTA * -1)) shards${NC}"
        elif [ "$PROGRESS_STALLED" = true ]; then
            echo -e "${YELLOW}⚠️  No progress - recovery may be stuck${NC}"
        fi
    fi
    
    echo ""
    echo "Press Ctrl+C to exit | Refreshing every 5 seconds..."
    
    # Update previous state
    PREV_RECOVERY_COUNT=$RECOVERY_COUNT
    PREV_UNASSIGNED=$UNASSIGNED
    
    sleep 5
done

