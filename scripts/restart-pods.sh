#!/bin/bash

# Twitter Consumer Pod Restart Script
# This script automatically restarts degraded Twitter consumer pods in the scoup namespace

NAMESPACE="putulero"

CLUSTER="--context=Net4"

kubectl $CLUSTER get pods -n $NAMESPACE | grep -v 'Running' | awk '{print $1}' | xargs kubectl $CLUSTER delete pod -n $NAMESPACE