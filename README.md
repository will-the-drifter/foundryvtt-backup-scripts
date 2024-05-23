# Backup and Restore Scripts

This repository contains a set of bash scripts for automating backup and restore operations for the Foundry VTT software. The scripts include functionalities for automated backups, manual backups, and restoration processes.

## Scripts

- `backup.sh`: Automates the backup process, creating incremental backups daily and full backups every 8 days.
- `manual_backup.sh`: Creates a full backup manually, deleting previous backups.
- `restore.sh`: Restores the system to a state from X days ago using full and incremental backups.
- `restore_success.sh`: Cleans up old backups and creates a new full backup after a successful restore.
- `restore_failed.sh`: Reverts the system to the previous state if a restore fails.
- `setup.sh`: Downloads all the scripts and removes itself after execution.

## Installation

1. Clone the repository:
    ```sh
    git clone https://github.com/yourusername/backup-scripts.git
    cd backup-scripts
    ```

2. Run the setup script:
    ```sh
    curl -o setup.sh https://raw.githubusercontent.com/yourusername/backup-scripts/main/setup.sh && bash setup.sh
    ```

3. Make the scripts executable:
    ```sh
    chmod +x /home/ubuntu/backup.sh
    chmod +x /home/ubuntu/manual_backup.sh
    chmod +x /home/ubuntu/restore.sh
    chmod +x /home/ubuntu/restore_success.sh
    chmod +x /home/ubuntu/restore_failed.sh
    ```

4. Set up the cron job to run the automated backup script daily at 4 AM:
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