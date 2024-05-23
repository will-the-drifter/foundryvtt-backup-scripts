# Backup and Restore Scripts

This repository contains a set of bash scripts for automating backup and restore operations for the Foundry VTT software. The scripts include functionalities for automated backups, manual backups, and restoration processes.

## Scripts

- `backup.sh`: Automates the backup process, creating incremental backups daily and full backups every 8 days.
- `manual_backup.sh`: Creates a full backup manually, deleting previous backups.
- `restore.sh`: Restores the system to a state from X days ago using full and incremental backups.
- `restore_success.sh`: Cleans up old backups and creates a new full backup after a successful restore.
- `restore_failed.sh`: Reverts the system to the previous state if a restore fails.

## Installation

1. Download the scripts:
    ```sh
    curl -o /home/ubuntu/backup.sh https://raw.githubusercontent.com/yourusername/backup-scripts/main/backup.sh
    curl -o /home/ubuntu/manual_backup.sh https://raw.githubusercontent.com/yourusername/backup-scripts/main/manual_backup.sh
    curl -o /home/ubuntu/restore.sh https://raw.githubusercontent.com/yourusername/backup-scripts/main/restore.sh
    curl -o /home/ubuntu/restore_success.sh https://raw.githubusercontent.com/yourusername/backup-scripts/main/restore_success.sh
    curl -o /home/ubuntu/restore_failed.sh https://raw.githubusercontent.com/yourusername/backup-scripts/main/restore_failed.sh
    ```

2. Make the scripts executable:
    ```sh
    chmod a+x /home/ubuntu/backup.sh
    chmod a+x /home/ubuntu/manual_backup.sh
    chmod a+x /home/ubuntu/restore.sh
    chmod a+x /home/ubuntu/restore_success.sh
    chmod a+x /home/ubuntu/restore_failed.sh
    ```

3. Set up the cron job to run the automated backup script daily at 4 AM:
    ```sh
    crontab -e
    ```

    Add the following line to the crontab file:
    ```sh
    0 4 * * * /home/ubuntu/backup.sh
    ```

## Usage

### Automated Backup

The `backup.sh` script is set up to run daily at 4 AM by the cron job.

### Manual Backup

To create a manual backup, run:
```sh
./manual_backup.sh
```

### Restore
To restore the system to a state from X days ago, run:

```sh
./restore.sh <days_ago>
```

### Post-Restore Success Cleanup
To clean up and create a new full backup after a successful restore, run:

```sh
./restore_success.sh
```

### Post-Restore Failure Cleanup
To revert to the previous state if a restore fails, run:

```sh
./restore_failed.sh
```