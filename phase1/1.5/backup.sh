#!/bin/bash
# Backup home directory to /backup with timestamp

BACKUP_DIR="/backup"
SOURCE_DIR="$HOME"
DATE=$(date +"%Y%m%d_%H%M%S")
FILENAME="home_backup_$DATE.tar.gz"

mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_DIR/$FILENAME" "$SOURCE_DIR"

echo "✅ Backup created at $BACKUP_DIR/$FILENAME"
