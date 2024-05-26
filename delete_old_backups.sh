#!/bin/bash

# Backup destination
BACKUP_DIR="/home/ubuntu/backup"

# Log file
LOG_FILE="/home/ubuntu/logs/delete_old_backups.log"

# Current date and time
DATE=$(date +%d-%m-%Y_%H-%M-%S)
TIME=$(date +%H:%M:%S)

# Logging function
log_message() {
    echo "[$(date '+%d-%m-%Y %H:%M:%S')] $1" | tee -a $LOG_FILE
}

log_message "Starting old backup deletion script..."

# Find and remove backups older than 3 hours
log_message "Removing backups older than 3 hours..."
DELETED_FILES=$(find $BACKUP_DIR -type f -mmin +180 -exec rm {} \; -print)

if [ -z "$DELETED_FILES" ]; then
    log_message "No old backups found to delete."
else
    log_message "Old backups removed successfully: $DELETED_FILES"
fi

log_message "Old backup deletion script completed on $DATE at $TIME"
