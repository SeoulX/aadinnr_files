#!/bin/bash

# Sample Log Generator Startup Script for ELK Stack

echo "🚀 ELK Stack Sample Log Generator"
echo "================================="

# Check if ingress is accessible
echo "🔍 Checking Logstash ingress accessibility..."

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 is not installed"
    exit 1
fi

# Check if requests module is available
if ! python3 -c "import requests" 2>/dev/null; then
    echo "📦 Installing required Python packages..."
    pip3 install requests
fi

# Test connection to Logstash via ingress
echo "🔍 Testing connection to Logstash via ingress..."
if curl -s http://logstash.local > /dev/null; then
    echo "✅ Logstash ingress is accessible"
else
    echo "❌ Cannot connect to Logstash via ingress (logstash.local)"
    echo "💡 Make sure:"
    echo "   1. Ingress is deployed: kubectl get ingress -n elastic-stack"
    echo "   2. /etc/hosts has: 192.168.39.200 logstash.local"
    echo "   3. Nginx ingress controller is running"
    exit 1
fi

echo ""
echo "🎯 Starting log generator..."
echo "📊 Logs will be sent to your ELK stack"
echo "⏹️  Press Ctrl+C to stop"
echo ""

# Start the log generator
python3 "$(dirname "$0")/log-generator.py"