function history_edit --description 'Edit fish history file directly in EDITOR'
    history save
    set -l hist_file "$XDG_DATA_HOME/fish/fish_history"
    if not test -f "$hist_file"
        set hist_file "$HOME/.local/share/fish/fish_history"
    end

    set -l editor_cmd "$EDITOR"
    if test -z "$editor_cmd"
        set editor_cmd nvim
    end

    $editor_cmd "$hist_file"
    history merge
end
