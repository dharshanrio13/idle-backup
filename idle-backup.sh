#!/bin/bash

SOURCE="/home/"
DEST="mnt/backup/home"

IDLE_LIMIT=120000 #2mins
FORCE_HOUR=21

STATE_FILE="/tmp/smart_backup_state"
LOG="$HOME/idle-backup.log"
NOTIF_ID=9999

RSYNC_PID=""
LAST_STATE=""
TODAY=$(date +%F)

notify() {
    notify-send -r $NOTIF_ID -t 120000 "Idle Backup" "$1"
}

log() {
    echo "$(date '+%F %T') | $1" >> "$LOG"
}

# dependency check
if ! command -v xprintidle >/dev/null; then
    notify-send "Idle Backup" "Install xprintidle: sudo apt install xprintidle"
    exit 1
fi

mkdir -p "$DEST"

notify "Idle backup system activated"
log "System started"

start_rsync() {
    notify "Backup started"
    log "Backup started"
    rsync -a --delete --partial --inplace "$SOURCE" "$DEST" &
    RSYNC_PID=$!
}

pause_rsync() {
    kill -STOP $RSYNC_PID 2>/dev/null
    notify "Backup paused"
    log "Paused"
}

resume_rsync() {
    kill -CONT $RSYNC_PID 2>/dev/null
    notify "Backup resumed"
    log "Resumed"
}

mark_done() {
    echo "$TODAY" > "$STATE_FILE"
}

while true; do

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
            pause_rsync
        fi

        LAST_STATE=$STATE
    fi

    if [ ! -z "$RSYNC_PID" ]; then
        if ! ps -p $RSYNC_PID > /dev/null; then
            notify "Backup completed ✅"
            log "Backup completed"
            mark_done
            RSYNC_PID=""
        fi
    fi

    sleep 5

done
