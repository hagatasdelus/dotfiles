#!/usr/bin/env bash
set -euo pipefail

readonly PID_FILE='/tmp/.caffeinate-sh.pid'

function notify() {
  local message="$1"
  osascript -e "display notification \"${message}\" with title \"Caffeinate\""
}

function get_running_pid() {
  if [[ ! -f "${PID_FILE}" ]]; then
    return 1
  fi

  local pid
  pid="$(cat "${PID_FILE}")"
  if kill -0 "${pid}" 2>/dev/null; then
    echo "${pid}"
    return 0
  fi

  return 1
}

function stop_caffeinate() {
  if [[ ! -f "${PID_FILE}" ]]; then
    return 0
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
  local mode="$1"
  local duration="$2"
  local description="$3"

  stop_caffeinate

  local flags=()
  case "${mode}" in
    "System")
      flags=(-i)
      ;;
    "Display")
      flags=(-d -i -u)
      ;;
    *)
      echo "Unknown mode: ${mode}" >&2
      return 1
      ;;
  esac

  if [[ -n "${duration}" ]]; then
    flags+=(-t "${duration}")
  fi

  set -m
  nohup caffeinate "${flags[@]}" </dev/null >/dev/null 2>&1 &
  local new_pid=$!
  disown "${new_pid}" 2>/dev/null || true
  set +m
  echo "${new_pid}" > "${PID_FILE}"

  echo "Started caffeinate (PID: ${new_pid}, Mode: ${mode}, Duration: ${duration:-Infinite})"
  notify "${description}"
}

function select_mode() {
  local running_pid
  local header_text="Mode:"
  if running_pid="$(get_running_pid)"; then
    header_text="Mode (Running: ${running_pid}):"
  fi

  local options=(
    "System"
    "Display"
    "Stop"
  )

  printf '%s\n' "${options[@]}" \
    | fzf --prompt="Mode > " \
        --height=10 \
        --layout=reverse \
        --header="${header_text}"
}

function select_duration() {
  local mode="$1"
  local options=(
    "Infinite"
    "30 min"
    "1 hour"
    "2 hours"
  )

  printf '%s\n' "${options[@]}" \
    | fzf --prompt="Duration > " \
        --height=10 \
        --layout=reverse \
        --header="Duration (${mode}):"
}

function handle_duration_selection() {
  local mode="$1"

  local duration_choice
  duration_choice="$(select_duration "${mode}")"
  if [[ -z "${duration_choice}" ]]; then
    echo "Cancelled."
    return 0
  fi

  local duration=""
  local time_label=""
  case "${duration_choice}" in
    "Infinite")
      duration=""
      time_label="Infinite"
      ;;
    "30 min")
      duration="1800"
      time_label="30m"
      ;;
    "1 hour")
      duration="3600"
      time_label="1h"
      ;;
    "2 hours")
      duration="7200"
      time_label="2h"
      ;;
    *)
      echo "Unexpected duration '${duration_choice}'" >&2
      return 1
      ;;
  esac

  start_caffeinate "${mode}" "${duration}" "${mode}: ${time_label} started"
}

function main() {
  local mode_choice
  mode_choice="$(select_mode)"

  if [[ -z "${mode_choice}" ]]; then
    echo "Cancelled."
    return 0
  fi

  case "${mode_choice}" in
    "System"|"Display")
      handle_duration_selection "${mode_choice}"
      ;;
    "Stop")
      stop_caffeinate
      notify "Stopped"
      ;;
    *)
      echo "Unexpected choice '${mode_choice}'" >&2
      return 1
      ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
