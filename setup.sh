#!/bin/bash

# Variables
REPO_URL="https://raw.githubusercontent.com/will-the-drifter/foundryvtt-backup-scripts/main/"
SCRIPTS=("backup.sh" "manual_backup.sh" "restore.sh" "restore_success.sh" "restore_failed.sh")
INSTALL_DIR="/home/ubuntu"
CRON_JOB="0 4 * * * $INSTALL_DIR/backup.sh"
SCRIPT_NAME=$(basename "$0")

# Function to log messages
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
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

# Make scripts executable
for SCRIPT in "${SCRIPTS[@]}"; do
    chmod +x "$INSTALL_DIR/$SCRIPT"
    if [ $? -ne 0 ]; then
        log "ERROR: Failed to make $SCRIPT executable"
        exit 1
    fi
done

# Setup cron job
(crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
if [ $? -ne 0 ]; then
    log "ERROR: Failed to set up cron job"
    exit 1
fi

log "Setup completed successfully."

# Delete this setup script
rm -- "$INSTALL_DIR/$SCRIPT_NAME"
if [ $? -ne 0 ]; then
    log "ERROR: Failed to delete setup script"
    exit 1
fi

log "Setup script deleted successfully."
