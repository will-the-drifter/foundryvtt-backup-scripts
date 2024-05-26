#!/bin/bash

# Log file for the wrapper script
LOG_FILE="/home/ubuntu/logs/run_backups.log"

# Logging function
log_message() {
    echo "[$(date '+%d-%m-%Y %H:%M:%S')] $1" | tee -a $LOG_FILE
}

log_message "Starting backup process..."

# Get the day of the week (1 = Monday, 2 = Tuesday, ..., 7 = Sunday)
DAY_OF_WEEK=$(date +%u)

if [ "$DAY_OF_WEEK" -eq 3 ]; then
    # If today is Wednesday (3), run delete_old_backups.sh
    log_message "Today is Wednesday. Running delete_old_backups.sh..."
    /home/ubuntu/delete_old_backups.sh
    if [ $? -eq 0 ]; then
        log_message "delete_old_backups.sh completed successfully."
    else
        log_message "delete_old_backups.sh encountered an error."
        exit 1
    fi
else
    log_message "Today is not Wednesday. Skipping delete_old_backups.sh."
fi

# Run backup.sh
log_message "Running backup.sh..."
/home/ubuntu/backup.sh
if [ $? -eq 0 ]; then
    log_message "backup.sh completed successfully."
else
    log_message "backup.sh encountered an error."
    exit 1
fi

log_message "Backup process completed."
