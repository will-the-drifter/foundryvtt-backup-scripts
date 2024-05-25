#!/bin/bash

# Ensure the script receives the correct number of parameters
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <days_ago|full>"
    exit 1
fi

# Variables
ARG=$1
BACKUP_REPO="file:///home/ubuntu/foundrybackup"
LOG_FILE="/home/ubuntu/duplicity_restore.log"
FOUNDRY_DIR="/home/ubuntu/foundry"
FOUNDRYUSERDATA_DIR="/home/ubuntu/foundryuserdata"
DATE=$(date +%d-%m-%Y-%H%M%S)

# Function to log messages
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - [restore.sh] - $1" | tee -a $LOG_FILE
}

# Ensure the script is run with sufficient permissions
if [ "$EUID" -ne 0 ]; then
    log "ERROR: Please run as root."
    exit 1
fi

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
    duplicity restore --force $BACKUP_REPO $FOUNDRY_DIR
    duplicity restore --force $BACKUP_REPO $FOUNDRYUSERDATA_DIR
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
    duplicity restore --force --time "$DATE" $BACKUP_REPO $FOUNDRY_DIR
    duplicity restore --force --time "$DATE" $BACKUP_REPO $FOUNDRYUSERDATA_DIR
    if [ $? -eq 0 ]; then
        log "Backup restored successfully to state from $DAYS_AGO days ago."
    else
        log "ERROR: Failed to restore backup."
        exit 1
    fi
}

# Main logic to choose the restore method
if [ "$ARG" == "full" ]; then
    restore_full_backup
else
    restore_incremental_backup "$ARG"
fi

# Change ownership of the restored files
log "Changing ownership of the restored files."
sudo chown -R ubuntu:ubuntu "$FOUNDRY_DIR"
sudo chown -R ubuntu:ubuntu "$FOUNDRYUSERDATA_DIR"

# Start the Foundry program
log "Starting Foundry program."
pm2 start foundry

log "Restore process completed successfully."
