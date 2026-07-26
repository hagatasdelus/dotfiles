#!/usr/bin/env bash
set -euo pipefail

readonly PID_FILE='/tmp/.caffeinate-sh.pid'

function notify() {
  local message="$1"
  osascript -e "display notification \"${message}\" with title \"Caffeinate\""
}

function stop_caffeinate() {
  if [[ ! -f "${PID_FILE}" ]]; then
    return
  fi

  local pid
  pid="$(cat "${PID_FILE}")"
  if kill -0 "${pid}" 2>/dev/null; then
    kill "${pid}"
    echo "Stopped caffeinate (PID: ${pid})"
  fi
  rm -f "${PID_FILE}"
}

function start_caffeinate() {
  local duration="$1"
  local description="$2"

  stop_caffeinate

  local flags=(-d)
  if [[ -n "${duration}" ]]; then
    flags+=(-t "${duration}")
  fi

  caffeinate "${flags[@]}" &
  local new_pid=$!
  echo "${new_pid}" > "${PID_FILE}"

  echo "Started caffeinate (PID: ${new_pid}, Duration: ${duration:-Infinite})"
  notify "${description}"
}

function main() {
  local options=(
    "Start (無制限)"
    "Start 30 min"
    "Start 1 hour"
    "Start 2 hours"
    "Stop"
  )

  local choice
  choice="$(printf '%s\n' "${options[@]}" \
    | fzf --prompt="Caffeinate > " \
        --height=10 \
        --layout=reverse \
        --header="Select duration or Stop:")"

  if [[ -z "${choice}" ]]; then
    echo "Cancelled."
    return 0
  fi

  case "${choice}" in
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
    *)
      echo "Unexpected choice '${choice}'" >&2
      return 1
      ;;
  esac
}

main "$@"
