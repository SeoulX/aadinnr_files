#!/bin/bash
echo "=== Server Health Report ($(date)) ==="
echo "CPU Load: $(uptime | awk '{print $10 $11 $12}')"
echo "Memory Usage:"
free -h
echo "Disk Usage:"
df -h /
