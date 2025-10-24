#!/bin/bash

# Twitter Consumer Pod Restart Script
# This script automatically restarts degraded Twitter consumer pods in the scoup namespace

NAMESPACE="article-story-value"

CLUSTER="--context=aws-mmi"

kubectl $CLUSTER get pods -n $NAMESPACE | grep 'article-story-value-v2-scaledjob'| awk '{print $1}' | xargs kubectl $CLUSTER delete pod -n $NAMESPACE

# | grep -v 'Running'