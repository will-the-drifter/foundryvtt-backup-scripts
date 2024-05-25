#!/bin/bash

# Ensure the script receives the correct number of parameters
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <days_ago|full>"
    exit 1
fi

# Variables
ARG=$1
BACKUP_REPO="/home/ubuntu/foundrybackup"
LOG_FILE="/home/ubuntu/borg_restore.log"
DATE=$(date +%d-%m-%Y-%H%M%S)

# Function to log messages
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - [borg_restore.sh] - $1" | tee -a $LOG_FILE
}

# Function to check available disk space
check_disk_space() {
    REQUIRED_SPACE=$(borg list $BACKUP_REPO --last 1 --format="{size}" | awk '{print $1}')
    AVAILABLE_SPACE=$(df /home/ubuntu | tail -1 | awk '{print $4}')
    
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
mkdir -p /home/ubuntu

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
    FULL_BACKUP=$(borg list $BACKUP_REPO --last 1 --format="{archive}")

    if [ -z "$FULL_BACKUP" ]; then
        log "ERROR: No full backup found."
        exit 1
    fi

    log "Full backup found: $FULL_BACKUP"
    borg extract $BACKUP_REPO::"$FULL_BACKUP"
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
    DATE=$(date -d "$DAYS_AGO days ago" +%Y-%m-%d)
    
    log "Restoring to a state from $DAYS_AGO days ago."

    # Find the backup archives from the specified date
    ARCHIVES=$(borg list $BACKUP_REPO --format="{archive} {end}" | awk -v date="$DATE" '$2 <= date {print $1}' | sort)

    if [ -z "$ARCHIVES" ]; then
        log "ERROR: No backups found for the specified date."
        exit 1
    fi

    # Restore the archives in order
    for ARCHIVE in $ARCHIVES; do
        log "Restoring backup: $ARCHIVE"
        borg extract $BACKUP_REPO::"$ARCHIVE"
        if [ $? -eq 0 ]; then
            log "Backup $ARCHIVE restored successfully."
        else
            log "ERROR: Failed to restore backup: $ARCHIVE"
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
