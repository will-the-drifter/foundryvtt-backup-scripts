#!/bin/bash

# Variables
LOG_FILE="/home/ubuntu/borg_restore_failed.log"

# Function to log messages
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - [borg_restore_failed.sh] - $1" | tee -a $LOG_FILE
}

# Ensure the script is run with sufficient permissions
if [ "$EUID" -ne 0 ]; then
    log "ERROR: Please run as root."
    exit 1
fi

# Stop the Foundry program
log "Stopping Foundry program."
pm2 stop foundry

# Remove the current foundry and foundryuserdata folders
log "Removing current directories."
rm -rf /home/ubuntu/foundry
rm -rf /home/ubuntu/foundryuserdata

# Restore the old foundry and foundryuserdata folders
log "Restoring old directories."
mv /home/ubuntu/foundry-old /home/ubuntu/foundry
mv /home/ubuntu/foundryuserdata-old /home/ubuntu/foundryuserdata

# Remove the old backup directories if they still exist
log "Cleaning up old backup directories."
rm -rf /home/ubuntu/foundry-old
rm -rf /home/ubuntu/foundryuserdata-old

# Start the Foundry program
log "Starting Foundry program."
pm2 start foundry

log "Restore failed process completed successfully."
