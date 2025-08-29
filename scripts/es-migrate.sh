#!/bin/bash

# Compare and Sync Elasticsearch Indices
# This script compares ALL indices between source and destination ES clusters
# and copies only the missing ones

# Configuration
SOURCE_HOST="http://13.214.69.186:9200"
DEST_HOST="http://elastic-user:pU387ZnjqMml@es-v4.media-meter.in"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Elasticsearch Index Comparison and Sync Tool ===${NC}"
echo ""

# Check if pattern filter is provided
INDEX_PATTERN=""
if [ "$1" != "" ]; then
    INDEX_PATTERN="$1"
    echo "Using index pattern: $INDEX_PATTERN"
else
    echo "No pattern specified - will compare ALL indices"
    echo "Usage: $0 [pattern] (e.g., $0 'articles_' or $0 'log')"
    echo ""
    read -p "Do you want to proceed with ALL indices? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled. You can run with a pattern like: $0 'articles_*'"
        exit 0
    fi
fi

# Function to get indices from a cluster
get_indices() {
    local host=$1
    local pattern=$2
    
    if [ -n "$pattern" ]; then
        # Use pattern if provided
        curl -s "${host}/_cat/indices/${pattern}?h=index" | sort
    else
        # Get all indices including system indices (those starting with .)
        curl -s "${host}/_cat/indices?h=index" | sort
    fi
}

# Function to copy a single index
copy_index() {
    local index=$1
    echo -e "${YELLOW}Processing: $index${NC}"
    
    # Get index info for reference
    local doc_count=$(curl -s "${SOURCE_HOST}/_cat/indices/${index}?h=docs.count" 2>/dev/null)
    local size=$(curl -s "${SOURCE_HOST}/_cat/indices/${index}?h=store.size" 2>/dev/null)
    echo "  Info: $doc_count docs, $size"
    
    # Copy mapping
    echo "  - Copying mapping..."
    elasticdump \
        --input="${SOURCE_HOST}/${index}" \
        --output="${DEST_HOST}/${index}" \
        --type=mapping \
        --quiet
    
    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}✓ Mapping copied${NC}"
    else
        echo -e "  ${RED}✗ Failed to copy mapping${NC}"
        return 1
    fi
    
    # Copy data
    echo "  - Copying data..."
    elasticdump \
        --input="${SOURCE_HOST}/${index}" \
        --output="${DEST_HOST}/${index}" \
        --type=data \
        --limit=1000 \
        --concurrency=1 \
        --timeout=120000 \
        --quiet
    
    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}✓ Data copied${NC}"
        return 0
    else
        echo -e "  ${RED}✗ Failed to copy data${NC}"
        return 1
    fi
}

# Function to sync data for existing indices
sync_existing_index_data() {
    local index=$1
    echo -e "${YELLOW}Syncing data for existing index: $index${NC}"
    elasticdump \
        --input="${SOURCE_HOST}/${index}" \
        --output="${DEST_HOST}/${index}" \
        --type=data \
        --limit=1000 \
        --concurrency=1 \
        --timeout=120000 \
        --overwrite=true \
        --quiet

    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}✓ Data synced for $index${NC}"
    else
        echo -e "  ${RED}✗ Failed to sync data for $index${NC}"
    fi
}

# Test connectivity
echo "Testing connectivity..."
SOURCE_STATUS=$(curl -s "${SOURCE_HOST}/_cluster/health" 2>/dev/null | jq -r '.status' 2>/dev/null)
DEST_STATUS=$(curl -s "${DEST_HOST}/_cluster/health" 2>/dev/null | jq -r '.status' 2>/dev/null)

if [ -z "$SOURCE_STATUS" ]; then
    echo -e "${RED}✗ Cannot connect to source cluster${NC}"
    exit 1
else
    echo -e "${GREEN}✓ Source cluster connected (status: $SOURCE_STATUS)${NC}"
fi

if [ -z "$DEST_STATUS" ]; then
    echo -e "${RED}✗ Cannot connect to destination cluster${NC}"
    exit 1
else
    echo -e "${GREEN}✓ Destination cluster connected (status: $DEST_STATUS)${NC}"
fi

echo ""

# Get indices from both clusters
echo "Discovering indices in source cluster..."
SOURCE_INDICES=$(get_indices "$SOURCE_HOST" "$INDEX_PATTERN")

if [ -z "$SOURCE_INDICES" ]; then
    echo -e "${RED}No indices found in source cluster${NC}"
    exit 1
fi

echo "Discovering indices in destination cluster..."
DEST_INDICES=$(get_indices "$DEST_HOST" "$INDEX_PATTERN")

# Create temporary files for comparison
SOURCE_FILE=$(mktemp)
DEST_FILE=$(mktemp)

echo "$SOURCE_INDICES" > "$SOURCE_FILE"
echo "$DEST_INDICES" > "$DEST_FILE"

# Find missing indices
MISSING_INDICES=$(comm -23 "$SOURCE_FILE" "$DEST_FILE")

# Clean up temp files
rm "$SOURCE_FILE" "$DEST_FILE"

# Display comparison results
echo ""
echo -e "${BLUE}=== Comparison Results ===${NC}"
echo ""

# Count indices
SOURCE_COUNT=$(echo "$SOURCE_INDICES" | wc -l)
DEST_COUNT=0
MISSING_COUNT=0

if [ -n "$DEST_INDICES" ]; then
    DEST_COUNT=$(echo "$DEST_INDICES" | wc -l)
fi

if [ -n "$MISSING_INDICES" ]; then
    MISSING_COUNT=$(echo "$MISSING_INDICES" | wc -l)
fi

echo "Source cluster indices: $SOURCE_COUNT"
echo "Destination cluster indices: $DEST_COUNT"
echo "Missing indices: $MISSING_COUNT"
echo ""

# Show indices by category
echo -e "${BLUE}Source indices by type:${NC}"
echo "$SOURCE_INDICES" | while read -r index; do
    if [[ $index == articles_* ]]; then
        echo -e "  ${GREEN}$index${NC} (articles)"
    elif [[ $index == log* ]]; then
        echo -e "  ${YELLOW}$index${NC} (logs)"
    elif [[ $index == .* ]]; then
        echo -e "  ${RED}$index${NC} (system - skipped)"
    else
        echo -e "  ${BLUE}$index${NC} (other)"
    fi
done
echo ""

if [ -n "$DEST_INDICES" ]; then
    echo -e "${BLUE}Destination indices:${NC}"
    echo "$DEST_INDICES" | sed 's/^/  /'
    echo ""
fi

if [ -n "$MISSING_INDICES" ] && [ "$MISSING_COUNT" -gt 0 ]; then
    echo -e "${RED}Missing indices (will be copied):${NC}"
    echo "$MISSING_INDICES" | while read -r index; do
        local doc_count=$(curl -s "${SOURCE_HOST}/_cat/indices/${index}?h=docs.count" 2>/dev/null)
        local size=$(curl -s "${SOURCE_HOST}/_cat/indices/${index}?h=store.size" 2>/dev/null)
        echo -e "  ${RED}$index${NC} ($doc_count docs, $size)"
    done
    echo ""
    
    # Show summary by type
    echo -e "${BLUE}Missing indices summary:${NC}"
    ARTICLES_COUNT=$(echo "$MISSING_INDICES" | grep -c "^articles_" || echo "0")
    LOGS_COUNT=$(echo "$MISSING_INDICES" | grep -c "^log" || echo "0")
    OTHER_COUNT=$(echo "$MISSING_INDICES" | grep -cv "^articles_\|^log" || echo "0")
    
    echo "  Articles indices: $ARTICLES_COUNT"
    echo "  Log indices: $LOGS_COUNT"
    echo "  Other indices: $OTHER_COUNT"
    echo ""
    
    # Ask for confirmation
    read -p "Do you want to copy the missing indices? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${BLUE}=== Starting Migration of Missing Indices ===${NC}"
        echo ""
        
        # Track success/failure
        SUCCESS_COUNT=0
        FAILED_COUNT=0
        FAILED_INDICES=()
        
        # Copy each missing index
        echo "$MISSING_INDICES" | while read -r index; do
            if [ -n "$index" ]; then
                if copy_index "$index"; then
                    echo -e "${GREEN}✓ Successfully copied: $index${NC}"
                    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
                else
                    echo -e "${RED}✗ Failed to copy: $index${NC}"
                    FAILED_COUNT=$((FAILED_COUNT + 1))
                    FAILED_INDICES+=("$index")
                fi
                echo ""
            fi
        done
        
        echo ""
        echo -e "${BLUE}=== Migration Summary ===${NC}"
        echo "Total missing indices: $MISSING_COUNT"
        echo -e "${GREEN}Successfully copied: $SUCCESS_COUNT${NC}"
        echo -e "${RED}Failed: $FAILED_COUNT${NC}"
        
        if [ "$FAILED_COUNT" -gt 0 ]; then
            echo ""
            echo -e "${RED}Failed indices:${NC}"
            printf '  %s\n' "${FAILED_INDICES[@]}"
            echo ""
            echo "You can retry failed indices individually with:"
            printf 'elasticdump --input="%s/%s" --output="%s/%s" --type=mapping\n' "$SOURCE_HOST" "${FAILED_INDICES[0]}" "$DEST_HOST" "${FAILED_INDICES[0]}"
        fi
        
    else
        echo "Migration cancelled."
    fi
else
    echo -e "${GREEN}✓ All indices are already synchronized!${NC}"
    echo "No missing indices found."
fi

# --- New logic: Sync documents in existing indices ---
# Find common indices
COMMON_INDICES=$(comm -12 <(echo "$SOURCE_INDICES") <(echo "$DEST_INDICES"))

if [ -n "$COMMON_INDICES" ]; then
    echo ""
    echo -e "${BLUE}=== Syncing Documents in Existing Indices ===${NC}"
    echo ""
    echo "$COMMON_INDICES" | while read -r index; do
        if [ -n "$index" ]; then
            sync_existing_index_data "$index"
        fi
    done
    echo ""
    echo -e "${GREEN}✓ Document sync for existing indices complete!${NC}"
fi

echo ""
echo "Done!"