#!/bin/bash

# Variables
SOURCE_FOLDERS=("/home/ubuntu/foundry" "/home/ubuntu/foundryuserdata")
BACKUP_FOLDER="/home/ubuntu/foundrybackup"
LOG_FILE="/home/ubuntu/backup.log"
DATE=$(date +%d-%m-%Y-%H%M%S)
FULL_BACKUP_INTERVAL_DAYS=8

# Function to log messages
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - [backup.sh] - $1" | tee -a $LOG_FILE
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

# Ensure the backup folder exists
mkdir -p $BACKUP_FOLDER

# Check disk space before starting the backup process
check_disk_space

# Determine if a new full backup is needed
LAST_FULL_BACKUP=$(find $BACKUP_FOLDER -name "*full-backup*.tar.gz" -mtime -$FULL_BACKUP_INTERVAL_DAYS | sort | head -n 1)

if [ -z "$LAST_FULL_BACKUP" ]; then
    # Create a new full backup
    BACKUP_TYPE="full-backup"
    SNAPSHOT_FILE="$BACKUP_FOLDER/snapshot-$DATE.snar"

    # Delete all existing backups and their snapshots
    log "Deleting all existing backups and snapshots."
    rm -f $BACKUP_FOLDER/*.tar.gz
    rm -f $BACKUP_FOLDER/*.snar
else
    # Create an incremental backup
    BACKUP_TYPE="incremental-backup"
    SNAPSHOT_FILE="$BACKUP_FOLDER/snapshot-$DATE.snar"
fi

# Stop the Foundry program
log "Stopping Foundry program."
pm2 stop foundry

# Loop through each source folder and create a backup
for SOURCE_FOLDER in "${SOURCE_FOLDERS[@]}"; do
    FOLDER_NAME=$(basename $SOURCE_FOLDER)
    BACKUP_FILE="$BACKUP_FOLDER/${FOLDER_NAME}-$BACKUP_TYPE-$DATE.tar.gz"
    
    # Create backup
    tar --listed-incremental=$SNAPSHOT_FILE -czf $BACKUP_FILE -C / ${SOURCE_FOLDER#/}
    if [ $? -eq 0 ]; then
        log "Backup complete: $BACKUP_FILE"
    else
        log "ERROR: Failed to create backup: $BACKUP_FILE"
    fi
done

# Start the Foundry program
log "Starting Foundry program."
pm2 start foundry

log "Backup process completed successfully."
