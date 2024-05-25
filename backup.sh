#!/bin/bash

# Variables
SOURCE_FOLDERS=("/home/ubuntu/foundry" "/home/ubuntu/foundryuserdata")
BACKUP_REPO="/home/ubuntu/foundrybackup"
LOG_FILE="/home/ubuntu/borg_backup.log"
DATE=$(date +%d-%m-%Y-%H%M%S)
FULL_BACKUP_INTERVAL_DAYS=8

# Function to log messages
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - [borg_backup.sh] - $1" | tee -a $LOG_FILE
}

# Function to check available disk space
check_disk_space() {
    REQUIRED_SPACE=$(du -cs ${SOURCE_FOLDERS[@]} | tail -1 | awk '{print $1}')
    AVAILABLE_SPACE=$(df $BACKUP_REPO | tail -1 | awk '{print $4}')
    
    if [ $REQUIRED_SPACE -gt $AVAILABLE_SPACE ]; then
        log "ERROR: Not enough disk space. Required: $REQUIRED_SPACE KB, Available: $AVAILABLE_SPACE KB"
        exit 1
    fi
}

# Initialize the backup repository if it doesn't exist
if [ ! -d "$BACKUP_REPO" ]; then
    borg init --encryption=repokey $BACKUP_REPO
fi

# Ensure the script is run with sufficient permissions
if [ "$EUID" -ne 0 ]; then
    log "ERROR: Please run as root."
    exit 1
fi

# Check disk space before starting the backup process
check_disk_space

# Determine if a new full backup is needed
LAST_FULL_BACKUP=$(borg list $BACKUP_REPO --last 1 --format="{end}" 2>/dev/null | grep -oP '\d{4}-\d{2}-\d{2}')

if [ -n "$LAST_FULL_BACKUP" ]; then
    LAST_FULL_BACKUP_TIMESTAMP=$(date -d "$LAST_FULL_BACKUP" +%s)
    CURRENT_TIMESTAMP=$(date +%s)
    DAYS_SINCE_LAST_BACKUP=$(( (CURRENT_TIMESTAMP - LAST_FULL_BACKUP_TIMESTAMP) / 86400 ))
else
    DAYS_SINCE_LAST_BACKUP=$FULL_BACKUP_INTERVAL_DAYS
fi

# Create a new full backup if the last one is older than the specified interval
if [ $DAYS_SINCE_LAST_BACKUP -ge $FULL_BACKUP_INTERVAL_DAYS ]; then
    log "Creating a new full backup"
    BACKUP_TYPE="full"
else
    log "Creating an incremental backup"
    BACKUP_TYPE="incremental"
fi

# Stop the Foundry program
log "Stopping Foundry program."
pm2 stop foundry

# Perform the backup using borg
for SOURCE_FOLDER in "${SOURCE_FOLDERS[@]}"; do
    ARCHIVE_NAME="$BACKUP_REPO::$SOURCE_FOLDER-$DATE"
    
    log "Starting borg backup for $SOURCE_FOLDER"
    borg create --stats --progress $ARCHIVE_NAME "$SOURCE_FOLDER"
    if [ $? -eq 0 ]; then
        log "Backup complete for $SOURCE_FOLDER to $ARCHIVE_NAME"
    else
        log "ERROR: Failed to backup $SOURCE_FOLDER"
    fi
done

# Start the Foundry program
log "Starting Foundry program."
pm2 start foundry

log "Backup process completed successfully."
