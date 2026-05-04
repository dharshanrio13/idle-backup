# Idle Backup 🔥

Automatic smart backup system for Linux.

## Features
- Idle-based backup
- Pause/Resume (no restart)
- Manual trigger
- Runs once per day
- Forced backup after 9PM
- Auto-start on boot
- Notifications + logging

## Warning!!
- This file backup system only backsup the /home folder 
- Other system files cannot be backedup with this tool
- Use different tools like timeshift for system backup
- this script backs up only use files!!!!!!!!!

## Setup needed
- Mount or create a file at /mnt/backup/home
- The file can be anything like external drive or seperate partition
- If any adjustment needed in destination just go to /usr/local/bin 
- Then find the idle-backup.sh file and modify the destination


## Usage 

- backupctl start  -> start force backup (Active mode)
- backupctl stop   -> stop force back up 
- backupctl status -> see the status
- automatically detects idle and runs in background

## Install

```bash
git clone https://github.com/dharshanrio13/idle-backup.git
cd idle-backup
bash install.sh

