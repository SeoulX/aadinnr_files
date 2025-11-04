#!/bin/bash

# Twitter Consumer Pod Restart Script
# This script automatically restarts degraded Twitter consumer pods in the scoup namespace

NAMESPACE="scoup"
CLUSTER="--context=Net3"

# Get matching pods
PODS=$(kubectl $CLUSTER get pods -n $NAMESPACE | grep -vE '(yt|pca-write|write-up)' | awk '{print $1}')

# Check if any pods were found
if [ -z "$PODS" ]; then
    echo "No matching pods found to restart."
    exit 0
fi

# Delete the pods
echo "Restarting pods:"
echo "$PODS"
echo "$PODS" | xargs -r kubectl $CLUSTER delete pod -n $NAMESPACE --grace-period=30

if [ $? -eq 0 ]; then
    echo "Pods restarted successfully."
else
    echo "Error: Failed to restart pods."
    exit 1
fi