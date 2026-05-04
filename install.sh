#!/bin/bash

SERVICE_NAME="idle-backup.service"
SCRIPT_NAME="idle-backup.sh"

BIN_PATH="/usr/local/bin"
SERVICE_PATH="$HOME/.config/systemd/user"

install_app() {
    echo "🚀 Installing Idle Backup..."

    sudo cp $SCRIPT_NAME $BIN_PATH/
    sudo cp backupctl $BIN_PATH/

    sudo chmod +x $BIN_PATH/$SCRIPT_NAME
    sudo chmod +x $BIN_PATH/backupctl

    mkdir -p $SERVICE_PATH
    cp $SERVICE_NAME $SERVICE_PATH/

    systemctl --user daemon-reload
    systemctl --user enable $SERVICE_NAME
    systemctl --user start $SERVICE_NAME

    loginctl enable-linger $USER

    echo "✅ Installed successfully!"
}

uninstall_app() {
    echo "🧹 Removing Idle Backup..."

    systemctl --user stop $SERVICE_NAME 2>/dev/null
    systemctl --user disable $SERVICE_NAME 2>/dev/null

    rm -f $SERVICE_PATH/$SERVICE_NAME

    sudo rm -f $BIN_PATH/$SCRIPT_NAME
    sudo rm -f $BIN_PATH/backupctl

    systemctl --user daemon-reload

    rm -f /tmp/force_backup
    rm -f /tmp/backup-progress.log
    rm -f $HOME/idle-backup.log

    read -p "Delete backup data also? (y/n): " choice
    if [ "$choice" == "y" ]; then
        rm -rf $HOME/backup/home
    fi

    echo "🗑️ Idle Backup removed successfully!"
}

if [ "$1" == "revert" ]; then
    uninstall_app
else
    install_app
fi
