#!/bin/bash

# Directories to backup
DIR1="/home/ubuntu/foundry"
DIR2="/home/ubuntu/foundryuserdata"

# Backup destination
BACKUP_DIR="/home/ubuntu/backup"

# Log file
LOG_FILE="/home/ubuntu/logs/manual_backup.log"

# Current date and time
DATE=$(date +%d-%m-%Y_%H-%M-%S)
TIME=$(date +%H:%M:%S)

# Logging function
log_message() {
    echo "[$(date '+%d-%m-%Y %H:%M:%S')] $1" | tee -a $LOG_FILE
}

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

log_message "Starting manual backup script..."

# Stop the PM2-managed application
log_message "Stopping the foundry application..."
pm2 stop foundry
if [ $? -eq 0 ]; then
    log_message "Foundry application stopped successfully."
else
    log_message "Error stopping the foundry application."
    exit 1
fi

# Create a new full backup
log_message "Creating a new full backup..."
NEW_FULL_BACKUP="$BACKUP_DIR/manual_full_backup_${DATE}.tar"
tar -cvf $NEW_FULL_BACKUP $DIR1 $DIR2 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    log_message "New full backup created: $NEW_FULL_BACKUP"
else
    log_message "Error creating new full backup: $NEW_FULL_BACKUP"
    exit 1
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

log_message "Manual backup completed on $DATE at $TIME"
