#!/bin/bash

# Backup destination
BACKUP_DIR="/home/ubuntu/backup"

# Log file
LOG_FILE="/home/ubuntu/logs/backup.log"

# Current date and time
DATE=$(date +%d-%m-%Y_%H-%M-%S)
TIME=$(date +%H:%M:%S)

# Logging function
log_message() {
    echo "[$(date '+%d-%m-%Y %H:%M:%S')] $1" | tee -a $LOG_FILE
}

log_message "Starting old backup deletion script..."

# Find the newest full backup
NEWEST_FULL_BACKUP=$(ls -t $BACKUP_DIR/full_backup_*.tar 2>/dev/null | head -n 1)

if [ -z "$NEWEST_FULL_BACKUP" ]; then
    log_message "Error: No full backups found."
    exit 1
fi

log_message "Newest full backup: $NEWEST_FULL_BACKUP"

# Remove backups older than the newest full backup
log_message "Removing backups older than the newest full backup..."
find $BACKUP_DIR -type f \( -name "full_backup_*.tar" -o -name "incremental_backup_*.tar" \) ! -newer "$NEWEST_FULL_BACKUP" -exec rm {} \; > /dev/null 2>&1
if [ $? -eq 0 ]; then
    log_message "Old backups removed successfully."
else
    log_message "Error removing old backups."
fi

log_message "Old backup deletion script completed on $DATE at $TIME"
