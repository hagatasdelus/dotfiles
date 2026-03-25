# Fire notification when command ends without the command execution pane having focus

if [[ -z "$WEZTERM_PANE" ]] && [[ -z "$TMUX_PANE" ]]; then
    return
fi

NOTIFY_ON_COMMAND_DURATION=${NOTIFY_ON_COMMAND_DURATION:-5}

_notify_cmd_start=""
_notify_in_prompt=0

# When PROMPT_COMMAND calls notify::prompt_hook, the DEBUG trap fires at the exact moment the function is called (before the function has even entered).
# This triggers with BASH_COMMAND="notify::prompt_hook"
# -> Since _notify_in_prompt remains 0, the flag has no effect
# -> Without the BASH_COMMAND check, it would override _notify_cmd_start
function notify::on_debug() {
    # Prevent DEBUG triggers from firing for the function call itself
    [[ "$BASH_COMMAND" == "notify::prompt_hook"* ]] && return
    # Prevent DEBUG triggers from firing for commands within the function
    (( _notify_in_prompt )) && return
    _notify_cmd_start=$(date +%s)
}
trap 'notify::on_debug' DEBUG

function notify::active_app_pid() {
    osascript -e \
        'tell application "System Events" to get the unix id of first process whose frontmost is true' \
        2>/dev/null
}

function notify::wezterm_is_focused() {
    local active_pid=$1
    command -v wezterm &>/dev/null && command -v jq &>/dev/null || return 1

    local focused_pane
    focused_pane=$(
        wezterm cli list-clients --format json 2>/dev/null \
        | jq -r --arg pid "$active_pid" \
            '.[] | select(.pid == ($pid|tonumber)) | .focused_pane_id'
    )
    [[ "$focused_pane" == "$WEZTERM_PANE" ]]
}

function notify::tmux_is_focused() {
    local active_pid=$1
    command -v tmux &>/dev/null || return 1

    local client_pid pane_id
    while read -r client_pid pane_id; do
        [[ -z "$client_pid" ]] && continue

        local pid=$client_pid
        local depth
        for (( depth = 0; depth < 5; depth++ )); do
            local ppid
            ppid=$(ps -p "$pid" -o ppid= 2>/dev/null | tr -d ' ')
            [[ -z "$ppid" || ppid -eq 0 ]] && break

            if (( ppid == active_pid )); then
                [[ "$pane_id" == "$TMUX_PANE" ]] && return 0
                return 1  # Focused but in another pane
            fi
            pid=$ppid
        done
    done < <(tmux list-clients -F '#{client_pid} #{pane_id}')

    return 1
}

# Notify if not focused
# Return 0: Current pane is focused (Do not notify)
# Return 1: Current pane is not focused or active app PID cannot be determined (Send notification)
function notify::current_pane_is_focused() {
    local active_pid
    active_pid=$(notify::active_app_pid)
    [[ -z "$active_pid" ]] && return 1

    if [[ -n "$WEZTERM_PANE" ]]; then
        notify::wezterm_is_focused "$active_pid"
    else
        notify::tmux_is_focused "$active_pid"
    fi
}

function notify::send() {
    local title=$1 msg=$2
    # Escape sequence for AppleScript string literals (requires \ to be processed first)
    msg=${msg//\\/\\\\}
    msg=${msg//\"/\\\"}
    osascript -e "display notification \"$msg\" with title \"$title\""
}

function notify::prompt_hook() {
    local exit_code=$?
    _notify_in_prompt=1

    if [[ -n "$_notify_cmd_start" ]]; then
        local now duration
        now=$(date +%s)
        duration=$(( now - _notify_cmd_start ))
        _notify_cmd_start=""

        if (( duration >= NOTIFY_ON_COMMAND_DURATION )) \
           && ! notify::current_pane_is_focused; then
            local last_cmd
            last_cmd=$(fc -ln -1 | sed 's/^[[:space:]]*//')
            notify::send "Command completed" \
                "$last_cmd returned $exit_code after ${duration}s"
        fi
    fi

    _notify_in_prompt=0
}

PROMPT_COMMAND="notify::prompt_hook${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
