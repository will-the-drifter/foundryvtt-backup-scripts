#!/bin/bash

# Variables
REPO_URL="https://raw.githubusercontent.com/yourusername/backup-scripts/main"
SCRIPTS=("backup.sh" "manual_backup.sh" "restore.sh" "restore_success.sh" "restore_failed.sh")
INSTALL_DIR="/home/ubuntu"
SCRIPT_NAME=$(basename "$0")
LOG_FILE="$INSTALL_DIR/setup.log"

# Function to log messages
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - [setup.sh] - $1" | tee -a $LOG_FILE
}

# Ensure the script is run with sufficient permissions
if [ "$EUID" -ne 0 ]; then
    log "ERROR: Please run as root."
    exit 1
fi

# Download scripts
for SCRIPT in "${SCRIPTS[@]}"; do
    log "Downloading $SCRIPT..."
    curl -o "$INSTALL_DIR/$SCRIPT" "$REPO_URL/$SCRIPT"
    if [ $? -ne 0 ]; then
        log "ERROR: Failed to download $SCRIPT"
        exit 1
    fi
done

log "Setup completed successfully."

# Delete this setup script
rm -- "$INSTALL_DIR/$SCRIPT_NAME"
if [ $? -ne 0 ]; then
    log "ERROR: Failed to delete setup script"
    exit 1
fi

log "Setup script deleted successfully."
