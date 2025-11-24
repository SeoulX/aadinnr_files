#!/bin/bash

# Twitter Consumer Pod Restart Script
# This script automatically restarts pods in a specified namespace (or all namespaces)

# Prompt if namespace is needed
read -p "Do you need to specify a namespace? (y/n, default: y): " NEED_NAMESPACE
NEED_NAMESPACE=${NEED_NAMESPACE:-y}

NAMESPACE=""
NAMESPACE_FLAG=""
if [[ "$NEED_NAMESPACE" =~ ^[Yy]$ ]]; then
    read -p "Enter namespace: " NAMESPACE
    NAMESPACE_FLAG="-n $NAMESPACE"
else
    echo "No namespace provided. Defaulting to all namespaces."
    NAMESPACE_FLAG="--all-namespaces"
fi

# Prompt for cluster context
read -p "Enter cluster context (e.g., Net3): " CLUSTER_CONTEXT
CLUSTER="--context=$CLUSTER_CONTEXT"

# Prompt for excluding pod statuses
echo ""
echo "Select pod statuses to EXCLUDE (select multiple by entering numbers separated by spaces):"
echo "1) Running"
echo "2) Pending"
echo "3) Error"
echo "4) CrashLoopBackOff"
echo "5) Completed"
echo "6) Terminating"
echo "7) None (restart all pods)"
echo ""
read -p "Enter your choices (e.g., 1 3 4 or 7): " SELECTIONS

# Build grep filter based on selections
EXCLUDE_FILTER=""
if [[ "$SELECTIONS" =~ "7" ]]; then
    # Include all pods
    EXCLUDE_FILTER=""
elif [ -n "$SELECTIONS" ]; then
    # Build filter to exclude selected statuses
    for selection in $SELECTIONS; do
        case $selection in
            1) EXCLUDE_FILTER="${EXCLUDE_FILTER}|Running" ;;
            2) EXCLUDE_FILTER="${EXCLUDE_FILTER}|Pending" ;;
            3) EXCLUDE_FILTER="${EXCLUDE_FILTER}|Error" ;;
            4) EXCLUDE_FILTER="${EXCLUDE_FILTER}|CrashLoopBackOff" ;;
            5) EXCLUDE_FILTER="${EXCLUDE_FILTER}|Completed" ;;
            6) EXCLUDE_FILTER="${EXCLUDE_FILTER}|Terminating" ;;
        esac
    done
    # Remove leading pipe
    EXCLUDE_FILTER=$(echo "$EXCLUDE_FILTER" | sed 's/^|//')
fi

# Get matching pods
if [ -z "$EXCLUDE_FILTER" ]; then
    # Include all pods
    PODS=$(kubectl $CLUSTER get pods $NAMESPACE_FLAG | tail -n +2 | awk '{print $1}')
else
    # Exclude selected statuses
    PODS=$(kubectl $CLUSTER get pods $NAMESPACE_FLAG | grep -vE "$EXCLUDE_FILTER" | awk '{print $1}')
fi

# Check if any pods were found
if [ -z "$PODS" ]; then
    echo "No matching pods found to restart."
    exit 0
fi

# Delete the pods
echo "Restarting pods:"
echo "$PODS"
echo "$PODS" | xargs -r kubectl $CLUSTER delete pod $NAMESPACE_FLAG --grace-period=30

if [ $? -eq 0 ]; then
    echo "Pods restarted successfully."
else
    echo "Error: Failed to restart pods."
    exit 1
fi