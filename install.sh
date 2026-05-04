#!/usr/bin/env bash
set -e

SERVICE_NAME="idle-backup.service"
SCRIPT_NAME="idle-backup.sh"
BIN_PATH="$HOME/.local/bin"
SERVICE_PATH="$HOME/.config/systemd/user"

install_app() {
    if [ "$(id -u)" -eq 0 ]; then
        echo "Please run install.sh as your normal user, not as root."
        exit 1
    fi

    echo "🚀 Installing Idle Backup..."

    mkdir -p "$BIN_PATH"
    mkdir -p "$SERVICE_PATH"

    cp "$SCRIPT_NAME" "$BIN_PATH/"
    cp backupctl "$BIN_PATH/"

    chmod +x "$BIN_PATH/$SCRIPT_NAME"
    chmod +x "$BIN_PATH/backupctl"

    cp "$SERVICE_NAME" "$SERVICE_PATH/"

    if command -v systemctl >/dev/null 2>&1; then
        systemctl --user daemon-reload
        systemctl --user enable "$SERVICE_NAME"
        systemctl --user start "$SERVICE_NAME"
    else
        echo "Warning: systemctl is not available. Install the service manually or run $BIN_PATH/$SCRIPT_NAME directly."
    fi

    if command -v loginctl >/dev/null 2>&1; then
        loginctl enable-linger "$USER" >/dev/null 2>&1 || true
    fi

    echo "✅ Installed successfully to $BIN_PATH"
    echo "If ~/.local/bin is not in your PATH, add it to ~/.profile or ~/.bashrc."
}

uninstall_app() {
    echo "🧹 Removing Idle Backup..."

    if command -v systemctl >/dev/null 2>&1; then
        systemctl --user stop "$SERVICE_NAME" 2>/dev/null || true
        systemctl --user disable "$SERVICE_NAME" 2>/dev/null || true
    fi

    rm -f "$SERVICE_PATH/$SERVICE_NAME"
    rm -f "$BIN_PATH/$SCRIPT_NAME"
    rm -f "$BIN_PATH/backupctl"
    rm -f /tmp/force_backup
    rm -f /tmp/backup-progress.log
    rm -f "$HOME/idle-backup.log"

    if [ -d "/mnt/backup/home" ]; then
        read -p "Delete default backup destination /mnt/backup/home also? (y/n): " choice
        if [ "$choice" == "y" ]; then
            rm -rf "/mnt/backup/home"
        fi
    fi

    echo "🗑️ Idle Backup removed successfully!"
}

if [ "$1" == "revert" ]; then
    uninstall_app
else
    install_app
fi
