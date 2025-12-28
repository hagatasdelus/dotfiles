if [[ -n "$WEZTERM_PANE" ]] || [[ -n "$TMUX_PANE" ]]; then
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

                local active_pid=$(osascript -e 'tell application "System Events" to get the unix id of first process whose frontmost is true' 2>/dev/null)
                if [[ -n "$active_pid" ]]; then
                    if [[ -n "$WEZTERM_PANE" ]]; then
                        if type wezterm >/dev/null 2>&1 && type jq >/dev/null 2>&1; then

                                local active_pane=$(wezterm cli list-clients --format json 2>/dev/null | \
                                    jq -r --arg pid "$active_pid" '.[] | select(.pid == ($pid|tonumber)) | .focused_pane_id')
                                if [[ "$active_pane" == "$WEZTERM_PANE" ]]; then
                                    should_notify=0
                                fi
                        fi
                    elif [[ -n "$TMUX_PANE" ]]; then
                        if type tmux >/dev/null 2>&1; then
                            local client_info_list=$(tmux list-clients -F '#{client_pid} #{pane_id}')
                            while read -r client_pid pane_id; do
                                if [[ -z "$client_pid" ]]; then continue; fi

                                local current_check_pid=$client_pid
                                local is_focused_client=0

                                for i in {1..5}; do
                                    local ppid=$(ps -p "$current_check_pid" -o ppid= 2>/dev/null | tr -d ' ')

                                    if [[ -z "$ppid" || "$ppid" -eq 0 ]]; then break; fi

                                    if [[ "$ppid" -eq "$active_pid" ]]; then
                                        is_focused_client=1
                                        break
                                    fi
                                    current_check_pid="$ppid"
                                done

                                if [[ "$is_focused_client" -eq 1 ]]; then
                                    if [[ "$pane_id" == "$TMUX_PANE" ]]; then
                                        should_notify=0
                                    fi
                                    break
                                fi
                            done <<< "$client_info_list"
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
fi
