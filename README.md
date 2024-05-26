# Backup and Restore Scripts

This repository contains a set of bash scripts for automating backup and restore operations for the Foundry VTT software. The scripts include functionalities for automated backups, manual backups, and restoration processes.

## Scripts

- `backup.sh`: Automates the backup process, creating incremental backups daily and full backups every Wednesday at 4 AM.
- `manual_backup.sh`: Creates a full backup manually without affecting other scheduled backups.
- `restore.sh`: Restores the system to a specified date using full and incremental backups.
- `restore_success.sh`: Cleans up old backups and creates a new full backup after a successful restore.
- `restore_failed.sh`: Reverts the system to the previous state if a restore fails.
- `delete_old_backups.sh`: Deletes old backups that are older than the most recent full backup.
- `run_backups.sh`: Wrapper script that runs `delete_old_backups.sh` on Wednesdays and then runs `backup.sh`.

## Installation

Download the scripts:

```bash
curl -o /home/ubuntu/backup.sh https://raw.githubusercontent.com/will-the-drifter/foundryvtt-backup-scripts/main/backup.sh
curl -o /home/ubuntu/manual_backup.sh https://raw.githubusercontent.com/will-the-drifter/foundryvtt-backup-scripts/main/manual_backup.sh
curl -o /home/ubuntu/restore.sh https://raw.githubusercontent.com/will-the-drifter/foundryvtt-backup-scripts/main/restore.sh
curl -o /home/ubuntu/restore_success.sh https://raw.githubusercontent.com/will-the-drifter/foundryvtt-backup-scripts/main/restore_success.sh
curl -o /home/ubuntu/restore_failed.sh https://raw.githubusercontent.com/will-the-drifter/foundryvtt-backup-scripts/main/restore_failed.sh
curl -o /home/ubuntu/delete_old_backups.sh https://raw.githubusercontent.com/will-the-drifter/foundryvtt-backup-scripts/main/delete_old_backups.sh
curl -o /home/ubuntu/run_backups.sh https://raw.githubusercontent.com/will-the-drifter/foundryvtt-backup-scripts/main/run_backups.sh
```

Make the scripts executable:

```bash
chmod a+x /home/ubuntu/backup.sh
chmod a+x /home/ubuntu/manual_backup.sh
chmod a+x /home/ubuntu/restore.sh
chmod a+x /home/ubuntu/restore_success.sh
chmod a+x /home/ubuntu/restore_failed.sh
chmod a+x /home/ubuntu/delete_old_backups.sh
chmod a+x /home/ubuntu/run_backups.sh
```

### Setup Cron Jobs
Set up the cron jobs to run the automated scripts:

```bash
sudo crontab -e
```

Add the following lines to the crontab file:

```cron
# Run the wrapper script every day at 4 AM
0 4 * * * /home/ubuntu/run_backups.sh
```

### Usage
#### Automated Backup

The run_backups.sh script is set up to run daily at 4 AM by the cron job. It runs delete_old_backups.sh first if it is Wednesday, followed by backup.sh.

#### Manual Backup
To create a manual backup, run:

```bash
sudo ./manual_backup.sh
```

#### Restore
To restore the system to a specified date, run:

```bash
sudo ./restore.sh
```
You will be prompted to enter the date and the incremental backup number (if applicable).

#### Post-Restore Success Cleanup
To clean up and create a new full backup after a successful restore, run:

```bash
sudo ./restore_success.sh
```

#### Post-Restore Failure Cleanup
To revert to the previous state if a restore fails, run:

```bash
sudo ./restore_failed.sh
```