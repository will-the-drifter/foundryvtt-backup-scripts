#!/bin/bash

# Directories to backup
DIR1="/home/ubuntu/foundry"
DIR2="/home/ubuntu/foundryuserdata"

# Backup destination
BACKUP_DIR="/home/ubuntu/backup"

# Log file
LOG_FILE="/home/ubuntu/logs/backup.log"
LOW_SPACE_LOG="/home/ubuntu/STORAGE_SPACE_LOW"
BACKUP_FILES_LOG_DIR="/home/ubuntu/logs/backup_files"
mkdir -p $BACKUP_FILES_LOG_DIR

# Snapshot file for incremental backups
SNAPSHOT_FILE="$BACKUP_DIR/snapshot.file"

# Current date and time
DATE=$(date +%d-%m-%Y_%H-%M-%S)
TIME=$(date +%H:%M:%S)

# Logging function
log_message() {
    echo "[$(date '+%d-%m-%Y %H:%M:%S')] $1" | tee -a $LOG_FILE
}

# Function to check available disk space
check_disk_space() {
    log_message "Checking disk space..."
    REQUIRED_SPACE=$(du -s $DIR1 $DIR2 | awk '{sum += $1 * 2} END {print sum}')
    AVAILABLE_SPACE=$(df /home/ubuntu | awk 'NR==2 {print $4}')
    
    log_message "Required space: $REQUIRED_SPACE KB, Available space: $AVAILABLE_SPACE KB"

    if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
        touch $LOW_SPACE_LOG
        log_message "Error: Not enough space for backup. Required: $REQUIRED_SPACE KB, Available: $AVAILABLE_SPACE KB"
        exit 1
    fi
    log_message "Sufficient disk space available."
}

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

log_message "Starting backup script..."

# Ensure directories exist
for DIR in "$DIR1" "$DIR2" "$BACKUP_DIR" "/home/ubuntu/logs"; do
    if [ ! -d "$DIR" ]; then
        mkdir -p "$DIR"
        chown ubuntu:ubuntu "$DIR"
        log_message "Created directory: $DIR"
    fi
done

# Check disk space before proceeding
check_disk_space

# Stop the PM2-managed application
log_message "Stopping the foundry application..."
pm2 stop foundry
if [ $? -eq 0 ]; then
    log_message "Foundry application stopped successfully."
else
    log_message "Error stopping the foundry application."
    exit 1
fi

# Determine the type of backup to create
LATEST_FULL=$(ls -t $BACKUP_DIR/full_backup_*.tar 2>/dev/null | head -n 1)
if [ -z "$LATEST_FULL" ]; then
    BACKUP_TYPE="full"
else
    BACKUP_TYPE="incremental"
    INCREMENTAL_COUNT=$(ls $BACKUP_DIR/incremental_backup_${DATE:0:10}_*.tar 2>/dev/null | wc -l)
    INCREMENTAL_COUNT=$((INCREMENTAL_COUNT + 1))
fi

if [ "$BACKUP_TYPE" == "full" ]; then
    log_message "Creating full backup..."
    FULL_BACKUP_FILE="$BACKUP_DIR/full_backup_${DATE}.tar"
    tar --listed-incremental=$SNAPSHOT_FILE -cvf $FULL_BACKUP_FILE $DIR1 $DIR2 > $BACKUP_FILES_LOG_DIR/full_backup_${DATE}.log 2>&1
    if [ $? -eq 0 ]; then
        log_message "Full backup created: full_backup_${DATE}.tar"
    else
        log_message "Error creating full backup: full_backup_${DATE}.tar"
    fi
else
    log_message "Creating incremental backup..."
    INCREMENTAL_BACKUP_FILE="$BACKUP_DIR/incremental_backup_${DATE:0:10}_${INCREMENTAL_COUNT}.tar"
    tar --listed-incremental=$SNAPSHOT_FILE -cvf $INCREMENTAL_BACKUP_FILE $DIR1 $DIR2 > $BACKUP_FILES_LOG_DIR/incremental_backup_${DATE:0:10}_${INCREMENTAL_COUNT}.log 2>&1
    if [ $? -eq 0 ]; then
        log_message "Incremental backup created: incremental_backup_${DATE:0:10}_${INCREMENTAL_COUNT}.tar"
    else
        log_message "Error creating incremental backup: incremental_backup_${DATE:0:10}_${INCREMENTAL_COUNT}.tar"
    fi
fi

# Start the PM2-managed application
log_message "Starting the foundry application..."
pm2 start foundry
if [ $? -eq 0 ]; then
    log_message "Foundry application started successfully."
else
    log_message "Error starting the foundry application."
    exit 1
fi

log_message "Backup completed on $DATE at $TIME"
