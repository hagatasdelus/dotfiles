#!/usr/bin/env bash
set -euo pipefail

PID_FILE="/tmp/.herdr_caffeinate.pid"

notify() {
    local msg="$1"
    osascript -e "display notification \"$msg\" with title \"Caffeinate (herdr)\""
}

stop_caffeinate() {
    if [ -f "$PID_FILE" ]; then
        local pid
        pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            echo "Stopped caffeinate (PID: $pid)"
        fi
        rm -f "$PID_FILE"
    fi
}

start_caffeinate() {
    local duration="$1"
    local desc="$2"

    stop_caffeinate

    if [ -z "$duration" ]; then
        caffeinate -d &
    else
        caffeinate -d -t "$duration" &
    fi
    local new_pid=$!
    echo "$new_pid" > "$PID_FILE"
    echo "Started caffeinate (PID: $new_pid, Duration: ${duration:-Infinite})"
    notify "$desc"
}

OPTIONS=(
    "Start (無制限)"
    "Start 30 min"
    "Start 1 hour"
    "Start 2 hours"
    "Stop"
)

CHOICE=$(printf "%s\n" "${OPTIONS[@]}" | fzf --prompt="Caffeinate > " --height=10 --layout=reverse --header="Select duration or Stop:")

if [ -z "$CHOICE" ]; then
    echo "Cancelled."
    exit 0
fi

case "$CHOICE" in
    "Start (無制限)")
        start_caffeinate "" "スリープを無制限に防止します。"
        ;;
    "Start 30 min")
        start_caffeinate "1800" "30分間スリープを防止します。"
        ;;
    "Start 1 hour")
        start_caffeinate "3600" "1時間スリープを防止します。"
        ;;
    "Start 2 hours")
        start_caffeinate "7200" "2時間スリープを防止します。"
        ;;
    "Stop")
        stop_caffeinate
        notify "停止しました。スリープが有効になります。"
        ;;
esac
