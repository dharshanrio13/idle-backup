# idle-backup

A lightweight Linux backup utility that automatically syncs your home directory when the desktop is idle, with pause/resume support and optional forced backups. It runs as a systemd user service and provides simple command-line controls via `backupctl`.

## Key features

- Idle-based automatic backup using desktop idle detection
- Pause/resume `rsync` without restarting the transfer
- Manual forced backup trigger with `backupctl start`
- Daily completion tracking to avoid repeated backups
- Forced backup at a configurable hour if no backup has completed
- Progress view in a terminal window and desktop notifications
- Runs as a user-level `systemd` service

## Requirements

- `xprintidle`
- `rsync`
- `notify-send` (from `libnotify`)
- One of: `gnome-terminal`, `xterm`, `konsole`, or `xfce4-terminal`
- X11 desktop session with `DISPLAY` set
- systemd user service support

## What it backs up

- Default source: `/home/`
- Default destination: `/mnt/backup/home`

> Warning: This repository only backs up your home directory data. It does not create full system snapshots or back up system/boot partitions.

## Installation

```bash
git clone https://github.com/dharshanrio13/idle-backup.git
cd idle-backup
bash install.sh
```

If `~/.local/bin` is not in your PATH, add it to `~/.profile` or `~/.bashrc`:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.profile
source ~/.profile
```

## Manual installation notes

The installer copies:

- `idle-backup.sh` to `~/.local/bin`
- `backupctl` to `~/.local/bin`
- `idle-backup.service` to `~/.config/systemd/user`

It also enables and starts the systemd user service automatically if `systemctl` is available.

## Usage

Start the backup service:

```bash
systemctl --user daemon-reload
systemctl --user enable --now idle-backup.service
```

Control the backup mode with `backupctl`:

- `backupctl start` — request an immediate forced backup
- `backupctl stop` — cancel forced backup mode
- `backupctl status` — show current mode and service state
- `backupctl progress` — show current rsync progress

To uninstall:

```bash
bash install.sh revert
```

## Testing the repository

1. Install the required packages for your distribution.
2. Ensure `/mnt/backup/home` exists and is writable, or edit `idle-backup.sh` to use a test source/destination.
3. Run `bash install.sh` as your normal user.
4. Start the service with `systemctl --user enable --now idle-backup.service`.
5. Trigger a manual backup:
   - `backupctl start`
6. View logs:
   - `tail -f "$HOME/idle-backup.log"`
   - `tail -f /tmp/backup-progress.log`
   - `journalctl --user -u idle-backup.service -f`

## Troubleshooting

- If the terminal progress window does not appear, check for a compatible terminal emulator and make sure your window manager is not hiding small windows.
- If `DISPLAY` is unset, the service cannot detect idle time under X11.
- If the service does not start automatically, run:

```bash
systemctl --user daemon-reload
systemctl --user enable --now idle-backup.service
```

## Customization

Edit `idle-backup.sh` to change these values:

- `SOURCE` — source folder to back up
- `DEST` — backup destination
- `IDLE_LIMIT` — idle threshold in milliseconds
- `FORCE_HOUR` — hour to force backup if none completed today
- `TERMINAL_GEOMETRY` — progress window size

## License

This repository does not include a license file. Add one if you want to share or distribute it publicly.

