#!/bin/bash

# Variables
SOURCE_FOLDERS=("/home/ubuntu/foundry" "/home/ubuntu/foundryuserdata")
BACKUP_REPO="file:///home/ubuntu/foundrybackup"
LOG_FILE="/home/ubuntu/duplicity_manual_backup.log"
DATE=$(date +%d-%m-%Y-%H%M%S)

# Function to log messages
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - [manual_backup.sh] - $1" | tee -a $LOG_FILE
}

# Ensure the script is run with sufficient permissions
if [ "$EUID" -ne 0 ]; then
    log "ERROR: Please run as root."
    exit 1
fi

# Stop the Foundry program
log "Stopping Foundry program."
pm2 stop foundry

# Perform the full backup for each source folder
for SOURCE_FOLDER in "${SOURCE_FOLDERS[@]}"; do
    log "Starting duplicity full backup for $SOURCE_FOLDER"
    duplicity full $SOURCE_FOLDER $BACKUP_REPO
    if [ $? -eq 0 ]; then
        log "Full backup complete for $SOURCE_FOLDER"
    else
        log "ERROR: Failed to create full backup for $SOURCE_FOLDER"
        exit 1
    fi
done

# Start the Foundry program
log "Starting Foundry program."
pm2 start foundry

log "Manual backup process completed successfully."
