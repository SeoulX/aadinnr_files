#!/bin/bash

LOGFILE=./server_health_$(date +%F).log

echo "==== SERVER HEALTH CHECK ====" > $LOGFILE
echo "Date: $(date)" >> $LOGFILE
echo "Uptime:" >> $LOGFILE
uptime >> $LOGFILE
echo "" >> $LOGFILE

echo "Disk Usage:" >> $LOGFILE
df -h >> $LOGFILE
echo "" >> $LOGFILE

echo "Memory Usage:" >> $LOGFILE
free -h >> $LOGFILE
echo "" >> $LOGFILE

echo "Top 5 Processes:" >> $LOGFILE
ps aux --sort=-%mem | head -n 6 >> $LOGFILE

echo "Health check complete. Results saved to $LOGFILE"

