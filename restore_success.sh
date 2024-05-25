#!/bin/bash

# Variables
BACKUP_REPO="/home/ubuntu/foundrybackup"
LOG_FILE="/home/ubuntu/borg_restore_success.log"
DATE=$(date +%d-%m-%Y-%H%M%S)

# Function to log messages
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - [borg_restore_success.sh] - $1" | tee -a $LOG_FILE
}

# Ensure the script is run with sufficient permissions
if [ "$EUID" -ne 0 ]; then
    log "ERROR: Please run as root."
    exit 1
fi

# Remove old backups and snapshots
log "Removing old backups and snapshots."
borg prune --stats --keep-daily=7 --keep-weekly=4 --keep-monthly=6 $BACKUP_REPO

# Perform a new full backup
log "Creating a new full backup."
backup.sh

# Remove the old backup directories
log "Removing old backup directories."
rm -rf /home/ubuntu/foundry-old
rm -rf /home/ubuntu/foundryuserdata-old

log "Restore success process completed successfully."
