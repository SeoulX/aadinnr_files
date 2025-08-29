#!/bin/bash
# Simple SSH troubleshooting script

TARGET_HOST=$1

if [ -z "$TARGET_HOST" ]; then
  echo "Usage: $0 <hostname_or_ip>"
  exit 1
fi

echo "🔍 Checking SSH connectivity to $TARGET_HOST..."

# 1. Check ping
ping -c 2 $TARGET_HOST > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "❌ Host unreachable (ping failed)"
  exit 1
fi
echo "✅ Host reachable"

# 2. Check if SSH port open
nc -zv $TARGET_HOST 22
if [ $? -ne 0 ]; then
  echo "❌ Port 22 is closed"
  exit 1
fi
echo "✅ SSH port 22 is open"

# 3. Try SSH
ssh -o BatchMode=yes -o ConnectTimeout=5 $TARGET_HOST "echo '✅ SSH login successful'" || echo "❌ SSH failed"
