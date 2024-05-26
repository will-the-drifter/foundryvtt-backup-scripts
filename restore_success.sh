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

# Function to check available disk space
check_disk_space() {
    log_message "Checking disk space..."
    REQUIRED_SPACE=$(du -s $DIR1 $DIR2 | awk '{sum += $1 * 2} END {print sum}')
    AVAILABLE_SPACE=$(df /home/ubuntu | awk 'NR==2 {print $4}')
    
    log_message "Required space: $REQUIRED_SPACE KB, Available space: $AVAILABLE_SPACE KB"

    if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
        log_message "Error: Not enough space for creating a new backup. Required: $REQUIRED_SPACE KB, Available: $AVAILABLE_SPACE KB"
        exit 1
    fi
    log_message "Sufficient disk space available."
}

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

log_message "Starting restore successful script..."

# Check disk space before proceeding
check_disk_space

# Ensure the backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
    chown ubuntu:ubuntu "$BACKUP_DIR"
    log_message "Created backup directory: $BACKUP_DIR"
fi

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

# Remove all existing backups
log_message "Removing all existing backups..."
rm -rf $BACKUP_DIR/*
if [ $? -eq 0 ]; then
    log_message "All existing backups removed successfully."
else
    log_message "Error removing existing backups."
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

log_message "Restore successful script completed on $DATE at $TIME"
