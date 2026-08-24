#
# Terminal notifications for long-running commands when the pane loses focus.
#

if [[ -z "${WEZTERM_PANE}" && -z "${TMUX_PANE}" ]]; then
  return 0
fi

typeset -g NOTIFY_ON_COMMAND_DURATION="${NOTIFY_ON_COMMAND_DURATION:-5}"
typeset -g _notify_cmd_start=""
typeset -g _notify_last_command=""

# Retrieve the PID of the frontmost application on macOS.
# Outputs:
#   Writes PID to stdout.
function notify::active_app_pid() {
  osascript -e \
    'tell application "System Events" to get the unix id of first process whose frontmost is true' \
    2>/dev/null
}

# Check if the active WezTerm pane matches current WEZTERM_PANE.
# Arguments:
#   active_pid: Process ID of the active frontmost application.
# Returns:
#   0 if focused, 1 otherwise.
function notify::wezterm_is_focused() {
  local active_pid="$1"
  command -v wezterm >/dev/null 2>&1 && command -v jq >/dev/null 2>&1 || return 1

  local focused_pane
  focused_pane="$(
    wezterm cli list-clients --format json 2>/dev/null \
    | jq -r --arg pid "${active_pid}" \
      '.[] | select(.pid == ($pid|tonumber)) | .focused_pane_id' 2>/dev/null
  )"
  [[ "${focused_pane}" == "${WEZTERM_PANE}" ]]
}

# Check if the active tmux pane matches current TMUX_PANE.
# Arguments:
#   active_pid: Process ID of the active frontmost application.
# Returns:
#   0 if focused, 1 otherwise.
function notify::tmux_is_focused() {
  local active_pid="$1"
  command -v tmux >/dev/null 2>&1 || return 1

  local client_pid pane_id
  while read -r client_pid pane_id; do
    [[ -z "${client_pid}" ]] && continue

    local pid="${client_pid}"
    local depth
    for (( depth = 0; depth < 5; depth++ )); do
      local ppid
      ppid="$(ps -p "${pid}" -o ppid= 2>/dev/null | tr -d ' ')"
      [[ -z "${ppid}" || "${ppid}" -eq 0 ]] && break

      if (( ppid == active_pid )); then
        [[ "${pane_id}" == "${TMUX_PANE}" ]] && return 0
        return 1
      fi
      pid="${ppid}"
    done
  done < <(tmux list-clients -F '#{client_pid} #{pane_id}' 2>/dev/null)

  return 1
}

# Check if current terminal pane is focused.
# Arguments:
#   None
# Returns:
#   0 if focused, 1 otherwise.
function notify::current_pane_is_focused() {
  local active_pid
  active_pid="$(notify::active_app_pid)"
  [[ -z "${active_pid}" ]] && return 1

  if [[ -n "${WEZTERM_PANE}" ]]; then
    notify::wezterm_is_focused "${active_pid}"
  else
    notify::tmux_is_focused "${active_pid}"
  fi
}

# Send desktop notification on macOS.
# Arguments:
#   title: Notification title.
#   msg: Notification message body.
function notify::send() {
  local title="$1"
  local msg="$2"

  msg="${msg//\\/\\\\}"
  msg="${msg//\"/\\\"}"
  osascript -e "display notification \"${msg}\" with title \"${title}\"" 2>/dev/null || true
}

# Preexec hook to record start time and command string.
# Arguments:
#   Command string being executed.
function notify::preexec() {
  _notify_cmd_start="${EPOCHSECONDS}"
  _notify_last_command="$1"
}

# Precmd hook to trigger notification if duration exceeds threshold.
function notify::precmd() {
  local exit_code=$?

  if [[ -n "${_notify_cmd_start}" ]]; then
    local duration=$(( EPOCHSECONDS - _notify_cmd_start ))
    _notify_cmd_start=""

    if (( duration >= NOTIFY_ON_COMMAND_DURATION )) && ! notify::current_pane_is_focused; then
      local last_cmd="${_notify_last_command}"
      notify::send "Command completed" \
        "${last_cmd} returned ${exit_code} after ${duration}s"
    fi
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec notify::preexec
add-zsh-hook precmd notify::precmd
