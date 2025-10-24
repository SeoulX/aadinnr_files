#!/bin/bash

# Twitter Consumer Pod Restart Script
# This script automatically restarts degraded Twitter consumer pods in the scoup namespace

NAMESPACE="serp-scrapers"

CLUSTER="--context=aws-mmi"

kubectl $CLUSTER get pods -n $NAMESPACE  | awk '{print $1}' | xargs kubectl $CLUSTER delete pod -n $NAMESPACE

# | grep -v 'Running'