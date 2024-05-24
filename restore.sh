#!/bin/bash

# Variables
BACKUP_FOLDER="/home/ubuntu/foundrybackup"
RESTORE_LOCATION="/home/ubuntu"
LOG_FILE="/home/ubuntu/restore.log"
DATE=$(date +%d-%m-%Y-%H%M%S)

# Function to log messages
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - [restore.sh] - $1" | tee -a $LOG_FILE
}

# Function to check available disk space
check_disk_space() {
    REQUIRED_SPACE=$(du -cs $BACKUP_FOLDER/*.tar.gz | tail -1 | awk '{print $1}')
    AVAILABLE_SPACE=$(df $RESTORE_LOCATION | tail -1 | awk '{print $4}')
    
    if [ $REQUIRED_SPACE -gt $AVAILABLE_SPACE ]; then
        log "ERROR: Not enough disk space. Required: $REQUIRED_SPACE KB, Available: $AVAILABLE_SPACE KB"
        exit 1
    fi
}

# Ensure the script is run with sufficient permissions
if [ "$EUID" -ne 0 ]; then
    log "ERROR: Please run as root."
    exit 1
fi

# Ensure restore location exists
mkdir -p $RESTORE_LOCATION

# Find the last full backup and determine how many days ago it was made
LAST_FULL_BACKUP=$(find $BACKUP_FOLDER -name "*full-backup*.tar.gz" | sort | tail -n 1)

if [ -z "$LAST_FULL_BACKUP" ]; then
    log "ERROR: No full backup found."
    exit 1
fi

LAST_FULL_BACKUP_DATE=$(basename $LAST_FULL_BACKUP | grep -oP '\d{2}-\d{2}-\d{4}')
LAST_FULL_BACKUP_TIMESTAMP=$(date -d "$LAST_FULL_BACKUP_DATE" +%s)
CURRENT_TIMESTAMP=$(date +%s)
DAYS_AGO=$(( (CURRENT_TIMESTAMP - LAST_FULL_BACKUP_TIMESTAMP) / 86400 ))

log "The last full backup was made $DAYS_AGO days ago."

# Prompt the user for the restore option
echo "Enter the number of days ago to restore, or type 'full' to restore the last full backup:"
read ARG

# Check disk space before stopping the Foundry program
check_disk_space

# Stop the Foundry program
log "Stopping Foundry program."
pm2 stop foundry

# Remove old backup directories if they exist
log "Removing old backup directories."
rm -rf /home/ubuntu/foundry-old
rm -rf /home/ubuntu/foundryuserdata-old

# Backup current foundry and foundryuserdata folders
log "Backing up current directories."
mv /home/ubuntu/foundry /home/ubuntu/foundry-old
mv /home/ubuntu/foundryuserdata /home/ubuntu/foundryuserdata-old

# Remove the original directories to ensure a clean restore
log "Removing original directories."
rm -rf /home/ubuntu/foundry
rm -rf /home/ubuntu/foundryuserdata

# Function to restore the last full backup
restore_full_backup() {
    log "Restoring the last full backup."
    FULL_BACKUP=$(find $BACKUP_FOLDER -name "*full-backup*.tar.gz" | sort | tail -n 1)

    if [ -z "$FULL_BACKUP" ]; then
        log "ERROR: No full backup found."
        exit 1
    fi

    log "Full backup found: $FULL_BACKUP"
    tar -xzf $FULL_BACKUP -C /
    if [ $? -eq 0 ]; then
        log "Full backup restored successfully."
    else
        log "ERROR: Failed to restore full backup."
        exit 1
    fi
}

# Function to restore to a state from X days ago
restore_incremental_backup() {
    DAYS_AGO=$1
    DATE=$(date -d "$DAYS_AGO days ago" +%d-%m-%Y)
    
    log "Restoring to a state from $DAYS_AGO days ago."

    # Find the full backup file
    FULL_BACKUP=$(find $BACKUP_FOLDER -name "*full-backup*.tar.gz" | sort | head -n 1)

    if [ -z "$FULL_BACKUP" ]; then
        log "ERROR: No full backup found."
        exit 1
    fi

    log "Full backup found: $FULL_BACKUP"

    # Find the incremental backups
    log "Finding incremental backups."
    INCREMENTAL_BACKUPS=$(find $BACKUP_FOLDER -name "*incremental-backup*.tar.gz" | sort)

    if [ -z "$INCREMENTAL_BACKUPS" ]; then
        log "ERROR: No incremental backups found."
        exit 1
    fi

    # Filter incremental backups up to the specified date
    log "Filtering incremental backups up to the specified date."
    INCREMENTAL_BACKUPS_TO_RESTORE=$(echo "$INCREMENTAL_BACKUPS" | while read line; do
        BACKUP_DATE=$(echo $line | grep -oP '\d{2}-\d{2}-\d{4}' | head -1)
        BACKUP_TIMESTAMP=$(date -d "$BACKUP_DATE" +%s)
        TARGET_TIMESTAMP=$(date -d "$DATE" +%s)

        if [ $BACKUP_TIMESTAMP -le $TARGET_TIMESTAMP ]; then
            echo $line
        fi
    done)

    if [ -z "$INCREMENTAL_BACKUPS_TO_RESTORE" ]; then
        log "ERROR: No incremental backups to restore."
        exit 1
    fi

    log "Incremental backups to restore: $INCREMENTAL_BACKUPS_TO_RESTORE"

    # Restore the full backup
    log "Restoring full backup."
    tar -xzf $FULL_BACKUP -C /
    if [ $? -eq 0 ]; then
        log "Full backup restored successfully."
    else
        log "ERROR: Failed to restore full backup."
        exit 1
    fi

    # Restore the incremental backups in order
    echo "$INCREMENTAL_BACKUPS_TO_RESTORE" | while read line; do
        log "Restoring incremental backup: $line"
        tar -xzf $line -C /
        if [ $? -eq 0 ]; then
            log "Incremental backup $line restored successfully."
        else
            log "ERROR: Failed to restore incremental backup: $line"
            exit 1
        fi
    done
}

# Main logic to choose the restore method
if [ "$ARG" == "full" ]; then
    restore_full_backup
else
    restore_incremental_backup "$ARG"
fi

# Start the Foundry program
log "Starting Foundry program."
pm2 start foundry

log "Restore process completed successfully."
