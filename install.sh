#!/bin/bash

echo "🚀 Installing Idle Backup..."

# copy files
sudo cp idle-backup.sh /usr/local/bin/
sudo cp backupctl /usr/local/bin/

# permissions
sudo chmod +x /usr/local/bin/idle-backup.sh
sudo chmod +x /usr/local/bin/backupctl

# systemd user service
mkdir -p ~/.config/systemd/user
cp idle-backup.service ~/.config/systemd/user/

# enable service
systemctl --user daemon-reload
systemctl --user enable idle-backup.service
systemctl --user start idle-backup.service

# allow running without login
loginctl enable-linger $USER

echo "✅ Installation complete!"
echo "Use commands:"
echo "  backupctl start"
echo "  backupctl stop"
echo "  backupctl status"
