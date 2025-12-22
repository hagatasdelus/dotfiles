export NOTIFY_ON_COMMAND_DURATION=5
_wez_cmd_start_time=""
_wez_is_checking_notification=0

function _wez_timer_start {
    if [[ "$_wez_is_checking_notification" -eq 1 ]]; then return; fi
    if [[ "$BASH_COMMAND" == "_wez_check_notification"* ]]; then return; fi

    _wez_cmd_start_time=$(date +%s)
}

trap '_wez_timer_start' DEBUG

function _wez_check_notification {
    local exit_code=$?

    _wez_is_checking_notification=1

    if [[ -n "$_wez_cmd_start_time" ]]; then
        local now=$(date +%s)
        local duration=$((now - _wez_cmd_start_time))
        _wez_cmd_start_time=""

        if [[ $duration -ge $NOTIFY_ON_COMMAND_DURATION ]]; then

            local should_notify=1

            if type wezterm >/dev/null 2>&1 && [[ -n "$WEZTERM_PANE" ]] && type jq >/dev/null 2>&1; then

                local active_pid=$(osascript -e 'tell application "System Events" to get the unix id of first process whose frontmost is true' 2>/dev/null)

                if [[ -n "$active_pid" ]]; then
                    local active_pane=$(wezterm cli list-clients --format json 2>/dev/null | \
                        jq -r --arg pid "$active_pid" '.[] | select(.pid == ($pid|tonumber)) | .focused_pane_id')

                    if [[ "$active_pane" == "$WEZTERM_PANE" ]]; then
                        should_notify=0
                    fi
                fi
            fi

            if [[ $should_notify -eq 1 ]]; then
                local last_cmd=$(fc -ln -1 | sed 's/^[[:space:]]*//')
                local msg="$last_cmd returned $exit_code after ${duration}s"
                msg=${msg//\"/\\\"}
                osascript -e "display notification \"$msg\" with title \"command completed\""
            fi
        fi
    fi

    _wez_is_checking_notification=0
}

PROMPT_COMMAND="_wez_check_notification; $PROMPT_COMMAND"
