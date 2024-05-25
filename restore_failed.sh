#!/bin/bash

# Directories to handle
DIR1="/home/ubuntu/foundry"
DIR2="/home/ubuntu/foundryuserdata"
OLD_DIR1="${DIR1}-old"
OLD_DIR2="${DIR2}-old"

# Log file
LOG_FILE="/home/ubuntu/logs/restore_failed.log"

# Current date and time
DATE=$(date +%d-%m-%Y_%H-%M-%S)
TIME=$(date +%H:%M:%S)

# Logging function
log_message() {
    echo "[$(date '+%d-%m-%Y %H:%M:%S')] $1" | tee -a $LOG_FILE
}

log_message "Starting restore failed script..."

# Remove the current directories and their contents
log_message "Removing current directories..."
rm -rf $DIR1/*
rm -rf $DIR2/*
rm -rf $DIR1
rm -rf $DIR2
if [ $? -eq 0 ]; then
    log_message "Current directories removed successfully."
else
    log_message "Error removing current directories."
    exit 1
fi

# Rename the old directories back to the originals
log_message "Restoring old directories..."
mv $OLD_DIR1 $DIR1
mv $OLD_DIR2 $DIR2
if [ $? -eq 0 ]; then
    log_message "Old directories restored successfully."
else
    log_message "Error restoring old directories."
    exit 1
fi

log_message "Restore failed script completed on $DATE at $TIME"
