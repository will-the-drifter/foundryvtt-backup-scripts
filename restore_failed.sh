#!/bin/bash

# Variables
LOG_FILE="/home/ubuntu/duplicity_restore_failed.log"
FOUNDRY_DIR="/home/ubuntu/foundry"
FOUNDRYUSERDATA_DIR="/home/ubuntu/foundryuserdata"

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

# Remove the current foundry and foundryuserdata folders
log "Removing current directories."
rm -rf $FOUNDRY_DIR
rm -rf $FOUNDRYUSERDATA_DIR

# Restore the old foundry and foundryuserdata folders
log "Restoring old directories."
mv /home/ubuntu/foundry-old $FOUNDRY_DIR
mv /home/ubuntu/foundryuserdata-old $FOUNDRYUSERDATA_DIR

# Start the Foundry program
log "Starting Foundry program."
pm2 start foundry

# Remove the old backup directories if they still exist
log "Cleaning up old backup directories."
rm -rf /home/ubuntu/foundry-old/*
rm -rf /home/ubuntu/foundryuserdata-old/*
rm -rf /home/ubuntu/foundry-old
rm -rf /home/ubuntu/foundryuserdata-old

log "Restore failed process completed successfully."
