#!/bin/bash

# Variables
LOG_FILE="/home/ubuntu/restore_failed.log"

# Function to log messages
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - [restore_failed.sh] - $1" | tee -a $LOG_FILE
}

# Ensure the script is run with sufficient permissions
if [ "$EUID" -ne 0 ]; then
    log "ERROR: Please run as root."
    exit 1
fi

# Stop the Foundry program
log "Stopping Foundry program."
pm2 stop foundry

# Delete the current foundry and foundryuserdata folders
log "Deleting current foundry and foundryuserdata folders."
rm -rf /home/ubuntu/foundry
rm -rf /home/ubuntu/foundryuserdata

# Restore the old backups
log "Restoring old backups."
mv /home/ubuntu/foundry-old /home/ubuntu/foundry
mv /home/ubuntu/foundryuserdata-old /home/ubuntu/foundryuserdata

# Remove old directories if they exist
log "Removing old directories."
rm -rf /home/ubuntu/foundry-old
rm -rf /home/ubuntu/foundryuserdata-old

# Start the Foundry program
log "Starting Foundry program."
pm2 start foundry

log "Restore failed. Reverted to previous state."
