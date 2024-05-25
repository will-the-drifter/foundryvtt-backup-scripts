#!/bin/bash

# Directories to handle
DIR1="/home/ubuntu/foundry"
DIR2="/home/ubuntu/foundryuserdata"
OLD_DIR1="${DIR1}-old"
OLD_DIR2="${DIR2}-old"

# Backup destination
BACKUP_DIR="/home/ubuntu/backup"

# Log file
LOG_FILE="/home/ubuntu/logs/restore_successful.log"

# Current date and time
DATE=$(date +%d-%m-%Y_%H-%M-%S)
TIME=$(date +%H:%M:%S)

# Logging function
log_message() {
    echo "[$(date '+%d-%m-%Y %H:%M:%S')] $1" | tee -a $LOG_FILE
}

log_message "Starting restore successful script..."

# Remove the old directories and their contents
log_message "Removing old directories and their contents..."
rm -rf $OLD_DIR1/*
rm -rf $OLD_DIR2/*
rm -rf $OLD_DIR1
rm -rf $OLD_DIR2
if [ $? -eq 0 ]; then
    log_message "Old directories removed successfully."
else
    log_message "Error removing old directories."
    exit 1
fi

# Create a new full backup
log_message "Creating a new full backup..."
tar --listed-incremental=$BACKUP_DIR/snapshot.file -cvf $BACKUP_DIR/full_backup_${DATE}.tar $DIR1 $DIR2 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    log_message "New full backup created: full_backup_${DATE}.tar"
else
    log_message "Error creating new full backup: full_backup_${DATE}.tar"
    exit 1
fi

# Remove older backups
log_message "Removing older backups..."
find $BACKUP_DIR -type f \( -name "full_backup_*.tar" -o -name "incremental_backup_*.tar" \) ! -newer $BACKUP_DIR/full_backup_${DATE}.tar -exec rm {} \; > /dev/null 2>&1
if [ $? -eq 0 ]; then
    log_message "Older backups removed successfully."
else
    log_message "Error removing older backups."
fi

log_message "Restore successful script completed on $DATE at $TIME"
