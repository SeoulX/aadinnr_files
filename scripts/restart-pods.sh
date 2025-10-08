#!/bin/bash

# Twitter Consumer Pod Restart Script
# This script automatically restarts degraded Twitter consumer pods in the scoup namespace

NAMESPACE="scrapy-drissionpage"
APP_NAME="scrapy-drissionpage-national-article-sj-searchsift"
CLUSTER="--context=Net4"

kubectl $CLUSTER get pods -n $NAMESPACE | grep $APP_NAME | grep 'Error' | awk '{print $1}' | xargs kubectl $CLUSTER delete pod -n $NAMESPACE