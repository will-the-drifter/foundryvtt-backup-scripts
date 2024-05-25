#!/bin/bash

# Variables
SOURCE_FOLDERS=("/home/ubuntu/foundry" "/home/ubuntu/foundryuserdata")
BACKUP_REPO="file:///home/ubuntu/foundrybackup"
LOG_FILE="/home/ubuntu/duplicity_backup.log"
DATE=$(date +%d-%m-%Y-%H%M%S)
FULL_BACKUP_INTERVAL_DAYS=7

# Function to log messages
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - [backup.sh] - $1" | tee -a $LOG_FILE
}

# Ensure the script is run with sufficient permissions
if [ "$EUID" -ne 0 ]; then
    log "ERROR: Please run as root."
    exit 1
fi

# Check if a full backup is needed
LAST_BACKUP=$(duplicity collection-status $BACKUP_REPO | grep "Full" | tail -1 | awk '{print $3}')
if [ -z "$LAST_BACKUP" ]; then
    DAYS_SINCE_LAST_BACKUP=$FULL_BACKUP_INTERVAL_DAYS
else
    LAST_BACKUP_DATE=$(date -d $LAST_BACKUP +%s)
    CURRENT_DATE=$(date +%s)
    DAYS_SINCE_LAST_BACKUP=$(( (CURRENT_DATE - LAST_BACKUP_DATE) / 86400 ))
fi

# Perform the backup
if [ $DAYS_SINCE_LAST_BACKUP -ge $FULL_BACKUP_INTERVAL_DAYS ]; then
    log "Performing a full backup"
    BACKUP_TYPE="full"
else
    log "Performing an incremental backup"
    BACKUP_TYPE="incremental"
fi

# Stop the Foundry program
log "Stopping Foundry program."
pm2 stop foundry

# Perform the backup for each source folder
for SOURCE_FOLDER in "${SOURCE_FOLDERS[@]}"; do
    log "Starting duplicity $BACKUP_TYPE backup for $SOURCE_FOLDER"
    duplicity $BACKUP_TYPE $SOURCE_FOLDER $BACKUP_REPO
    if [ $? -eq 0 ]; then
        log "$BACKUP_TYPE backup complete for $SOURCE_FOLDER"
    else
        log "ERROR: Failed to create $BACKUP_TYPE backup for $SOURCE_FOLDER"
        exit 1
    fi
done

# Start the Foundry program
log "Starting Foundry program."
pm2 start foundry

log "Backup process completed successfully."
