function fish_right_prompt --description 'Right prompt with command completion notification'
    set -f check_neovim
    if test -n "$CMD_DURATION"; and test $CMD_DURATION -gt $NOTIFY_ON_COMMAND_DURATION
        if type -q wezterm; and test -n "$WEZTERM_PANE"
            set -l active_pid (osascript -e 'tell application "System Events" to get the unix id of first process whose frontmost is true' 2>/dev/null)
            set -l active_pane (wezterm cli list-clients --format json 2>/dev/null | /usr/bin/ruby -r json -e 'puts JSON.parse($<.read).find{|x|x["pid"]=='$active_pid'}&.[]"focused_pane_id"' 2>/dev/null)
            if test -n "$active_pane"; and test "$WEZTERM_PANE" -eq "$active_pane"
                set -f check_neovim 1
            end
        else
            set -f check_neovim 1
        end

        if test -n "$check_neovim"
            if test -z "$NVIM"; or not type -q nvr
                return
            end
            set -l pid (nvr --remote-expr 'luaeval("vim.F.npcall(vim.fn.jobpid, vim.bo.channel)")' 2>/dev/null)
            if test "$fish_pid" = "$pid"
                return
            end
        end

        set -l duration (bc -S2 -e "$CMD_DURATION / 1000" 2>/dev/null)
        set -l last_cmd (history | head -1)
        set -l msg "$last_cmd returned $status after {$duration}s"
        set -l escaped (string replace -a '\\' '\\\\' -- "$msg")
        set escaped (string replace -a '"' '\\"' -- "$escaped")

        if test -n "$NVIM"; and type -q nvr
            nvr --remote-send "<Cmd>lua vim.notify(\"$escaped\", vim.log.levels.WARN, { title = \"command completed\" })<CR>" 2>/dev/null
        else
            osascript -e "display notification \"$escaped\" with title \"command completed\"" 2>/dev/null
        end
    end
end
