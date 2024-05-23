#!/bin/bash

# Variables
BACKUP_FOLDER="/home/ubuntu/foundrybackup"
LOG_FILE="/home/ubuntu/restore_success.log"
DATE=$(date +%d-%m-%Y-%H%M%S)
SOURCE_FOLDERS=("/home/ubuntu/foundry" "/home/ubuntu/foundryuserdata")

# Function to log messages
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - [restore_success.sh] - $1" | tee -a $LOG_FILE
}

# Function to check available disk space
check_disk_space() {
    REQUIRED_SPACE=$(du -cs ${SOURCE_FOLDERS[@]} | tail -1 | awk '{print $1}')
    AVAILABLE_SPACE=$(df $BACKUP_FOLDER | tail -1 | awk '{print $4}')
    
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

# Remove old backup directories
log "Removing old backup directories."
rm -rf /home/ubuntu/foundry-old
rm -rf /home/ubuntu/foundryuserdata-old

# Delete all existing backups and snapshot files
log "Deleting all existing backups and snapshot files."
rm -f $BACKUP_FOLDER/*.tar.gz
rm -f $BACKUP_FOLDER/*.snar

# Ensure the backup folder exists
mkdir -p $BACKUP_FOLDER

# Check disk space before stopping the Foundry program
check_disk_space

# Stop the Foundry program
log "Stopping Foundry program."
pm2 stop foundry

# Create a new full backup
for SOURCE_FOLDER in "${SOURCE_FOLDERS[@]}"; do
    FOLDER_NAME=$(basename $SOURCE_FOLDER)
    BACKUP_FILE="$BACKUP_FOLDER/${FOLDER_NAME}-full-backup-$DATE.tar.gz"
    SNAPSHOT_FILE="$BACKUP_FOLDER/snapshot-$DATE.snar"
    
    # Create full backup
    tar --listed-incremental=$SNAPSHOT_FILE -czf $BACKUP_FILE -C / ${SOURCE_FOLDER#/}
    if [ $? -eq 0 ]; then
        log "Full backup complete: $BACKUP_FILE"
    else
        log "ERROR: Failed to create full backup: $BACKUP_FILE"
    fi
done

# Start the Foundry program
log "Starting Foundry program."
pm2 start foundry

log "Restore success cleanup completed successfully."
