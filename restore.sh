#!/bin/bash

# Directories to restore
DIR1="/home/ubuntu/foundry"
DIR2="/home/ubuntu/foundryuserdata"

# Backup destination
BACKUP_DIR="/home/ubuntu/backup"

# Log file
LOG_FILE="/home/ubuntu/logs/restore.log"

# Snapshot file for incremental backups
SNAPSHOT_FILE="$BACKUP_DIR/snapshot.file"

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
        log_message "Error: Not enough space for restore. Required: $REQUIRED_SPACE KB, Available: $AVAILABLE_SPACE KB"
        exit 1
    fi
    log_message "Sufficient disk space available."
}

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

log_message "Starting restore script..."

# Check disk space before proceeding
check_disk_space

# Prompt user for the backup date to restore
read -p "Enter the date of the backup to restore (format: dd-mm-yyyy): " RESTORE_DATE

# List available backups for the specified date
BACKUP_FILES=$(ls $BACKUP_DIR/*_backup_${RESTORE_DATE}_*.tar 2>/dev/null)
if [ -z "$BACKUP_FILES" ]; then
    log_message "Error: No backups found for the specified date."
    exit 1
fi

echo "Available backups for $RESTORE_DATE:"
echo "$BACKUP_FILES"

INCREMENTAL_BACKUPS_COUNT=$(ls $BACKUP_DIR/incremental_backup_${RESTORE_DATE}_*.tar 2>/dev/null | wc -l)

if [ "$INCREMENTAL_BACKUPS_COUNT" -gt 1 ]; then
    read -p "Enter the incremental backup number to restore up to (leave empty to include all backups): " RESTORE_INCREMENT
else
    RESTORE_INCREMENT=$INCREMENTAL_BACKUPS_COUNT
fi

# Stop the PM2-managed application
log_message "Stopping the foundry application..."
pm2 stop foundry
if [ $? -eq 0 ]; then
    log_message "Foundry application stopped successfully."
else
    log_message "Error stopping the foundry application."
    exit 1
fi

# Make temporary copies of the current directories
log_message "Creating temporary copies of the current directories..."
mv $DIR1 "${DIR1}-old"
mv $DIR2 "${DIR2}-old"
if [ $? -eq 0 ]; then
    log_message "Temporary copies created successfully."
else
    log_message "Error creating temporary copies."
    exit 1
fi

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

# Ensure the directories exist
mkdir -p $DIR1
mkdir -p $DIR2
chown ubuntu:ubuntu $DIR1 $DIR2

# Restore the full backup
log_message "Restoring the full backup from $RESTORE_DATE..."
FULL_BACKUP_FILE=$(ls -t $BACKUP_DIR/full_backup_${RESTORE_DATE}_*.tar 2>/dev/null | head -n 1)
if [ -z "$FULL_BACKUP_FILE" ]; then
    log_message "Error: No full backup found for the specified date."
    exit 1
fi

tar --listed-incremental=$SNAPSHOT_FILE -xvf $FULL_BACKUP_FILE -C / > /dev/null 2>&1
if [ $? -eq 0 ]; then
    log_message "Full backup restored successfully."
else
    log_message "Error restoring full backup."
    exit 1
fi

# Restore incremental backups if specified
if [ -n "$RESTORE_INCREMENT" ]; then
    log_message "Restoring incremental backups up to number $RESTORE_INCREMENT..."
    INCREMENTAL_BACKUPS=$(ls $BACKUP_DIR/incremental_backup_${RESTORE_DATE}_*.tar 2>/dev/null | awk -v inc="$RESTORE_INCREMENT" '{split($0, a, "_"); split(a[4], b, "."); if (b[1] <= inc) print}')
else
    log_message "Restoring all incremental backups..."
    INCREMENTAL_BACKUPS=$(ls $BACKUP_DIR/incremental_backup_${RESTORE_DATE}_*.tar 2>/dev/null)
fi

if [ -n "$INCREMENTAL_BACKUPS" ]; then
    for INCREMENTAL_BACKUP_FILE in $INCREMENTAL_BACKUPS; do
        tar --listed-incremental=$SNAPSHOT_FILE -xvf $INCREMENTAL_BACKUP_FILE -C / > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            log_message "Incremental backup $INCREMENTAL_BACKUP_FILE restored successfully."
        else
            log_message "Error restoring incremental backup $INCREMENTAL_BACKUP_FILE."
            exit 1
        fi
    done
else
    log_message "No incremental backups found for the specified date."
fi

# Start the PM2-managed application
log_message "Starting the foundry application..."
pm2 start foundry
if [ $? -eq 0 ]; then
    log_message "Foundry application started successfully."
else
    log_message "Error starting the foundry application."
    exit 1
fi

log_message "Restore completed on $DATE at $TIME"
