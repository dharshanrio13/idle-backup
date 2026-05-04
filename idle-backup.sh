#!/usr/bin/env bash

SOURCE="/home/"
DEST="/mnt/backup/home"
IDLE_LIMIT=10000 # 10 seconds in milliseconds
FORCE_HOUR=21

STATE_FILE="/tmp/smart_backup_state"
LOG="$HOME/idle-backup.log"
RSYNC_LOG="/tmp/backup-progress.log"
NOTIF_ID=9999

RSYNC_PID=""
LAST_STATE=""

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -r "$NOTIF_ID" -t 30000 "Idle Backup" "$1" 2>/dev/null || echo "[Idle Backup] $1"
    else
        echo "[Idle Backup] $1"
    fi
}

notify_temp() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -r "$NOTIF_ID" -t 30000 "Idle Backup" "$1" 2>/dev/null || echo "[Idle Backup] $1"
    else
        echo "[Idle Backup] $1"
    fi
}

log() {
    echo "$(date '+%F %T') | $1" >> "$LOG"
}

require_command() {
    command -v "$1" >/dev/null 2>&1
}


start_rsync() {
    if [ -n "$RSYNC_PID" ] && ps -p "$RSYNC_PID" >/dev/null 2>&1; then
        log "Rsync already running with PID $RSYNC_PID"
        return
    fi

    if ! require_command xprintidle; then
        notify "Missing dependency: xprintidle"
        log "xprintidle not installed"
        exit 1
    fi

    if ! require_command rsync; then
        notify "Missing dependency: rsync"
        log "rsync not installed"
        exit 1
    fi

    if [ -z "$DISPLAY" ]; then
        notify "Idle Backup requires an X11 desktop session"
        log "No DISPLAY available"
        exit 1
    fi

    mkdir -p "$DEST"

    if ! df "$DEST" >/dev/null 2>&1; then
        notify "Backup destination not accessible"
        log "Backup destination not accessible"
        return
    fi

    if ! touch "$DEST/.backup_test" 2>/dev/null || ! rm "$DEST/.backup_test" 2>/dev/null; then
        notify "Backup destination not writable"
        log "Backup destination not writable"
        return
    fi

    notify "Backup started"
    log "Backup started"
    rsync -a --delete --partial --inplace --info=progress2 "$SOURCE" "$DEST" > "$RSYNC_LOG" 2>&1 &
    RSYNC_PID=$!
}

pause_rsync() {
    if [ -n "$RSYNC_PID" ] && ps -p "$RSYNC_PID" >/dev/null 2>&1; then
        kill -STOP "$RSYNC_PID" 2>/dev/null
        notify_temp "Backup paused"
        log "Paused"
    fi
}

resume_rsync() {
    if [ -n "$RSYNC_PID" ] && ps -p "$RSYNC_PID" >/dev/null 2>&1; then
        kill -CONT "$RSYNC_PID" 2>/dev/null
        notify_temp "Backup resumed"
        log "Resumed"
    fi
}

mark_done() {
    echo "$TODAY" > "$STATE_FILE"
}

while true; do
    TODAY=$(date +%F)
    NOW_HOUR=$(date +%H)
    IDLE=$(xprintidle 2>/dev/null)
    [ -z "$IDLE" ] && IDLE=0

    if [ ! -f "$STATE_FILE" ] || ! grep -q "$TODAY" "$STATE_FILE"; then
        DONE_TODAY=0
    else
        DONE_TODAY=1
    fi

    if [ -f /tmp/force_backup ]; then
        STATE="FORCED"
    elif [ "$NOW_HOUR" -ge "$FORCE_HOUR" ] && [ "$DONE_TODAY" -eq 0 ]; then
        STATE="FORCED"
    elif [ "$IDLE" -gt "$IDLE_LIMIT" ]; then
        STATE="IDLE"
    else
        STATE="ACTIVE"
    fi

    if [ "$STATE" != "$LAST_STATE" ]; then
        if [ "$STATE" = "IDLE" ] || [ "$STATE" = "FORCED" ]; then
            if [ "$DONE_TODAY" -eq 1 ]; then
                LAST_STATE=$STATE
                sleep 5
                continue
            fi

            if [ "$STATE" = "FORCED" ]; then
                notify "Forced backup running"
            else
                notify "Idle detected → backup running"
            fi

            if [ -z "$RSYNC_PID" ]; then
                start_rsync
            else
                resume_rsync
            fi
        else
            notify_temp "System active, backup paused"
            pause_rsync
        fi
        LAST_STATE=$STATE
    fi

    if [ -n "$RSYNC_PID" ]; then
        if ! ps -p "$RSYNC_PID" >/dev/null 2>&1; then
            notify "Backup completed ✅"
            log "Backup completed"
            mark_done
            RSYNC_PID=""
        fi
    fi

    sleep 5
 done
