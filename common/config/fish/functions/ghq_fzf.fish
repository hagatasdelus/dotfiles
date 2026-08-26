function __ghq_fzf_get_self_bin --description 'Get absolute path of this script file for subshell execution'
    set -l self_file (functions -D ghq_fzf 2>/dev/null; or status filename)
    set -l resolved (realpath "$self_file" 2>/dev/null; or echo "$self_file")
    echo "$resolved"
end

function __ghq_fzf_get_root --description 'Get root directory of ghq repositories'
    set -l root (ghq root 2>/dev/null); or true
    if test (count $root) -gt 0; and test -n "$root[1]"
        echo "$root[1]"
    else
        echo "$HOME/dev/ghq"
    end
end

function __ghq_fzf_get_list --description 'Retrieve list of repositories managed by ghq'
    set -l list (ghq list 2>/dev/null); or begin
        echo "Error: ghq is not installed." >&2
        return 1
    end
    string join \n $list
end

function __ghq_fzf_save_history --description 'Save selected repository to history file' -a repo_rel history_file
    test (count $repo_rel) -eq 0; or test -z "$repo_rel"; and return 0
    test (count $history_file) -eq 0; or test -z "$history_file"; and return 0

    set -l dir (dirname "$history_file")
    mkdir -p "$dir"

    set -l tmp (mktemp)
    if test -f "$history_file"
        grep -v -F -x "$repo_rel" "$history_file" > "$tmp" 2>/dev/null; or true
    end
    echo "$repo_rel" >> "$tmp"
    mv "$tmp" "$history_file"
end

function __ghq_fzf_get_ordered_list --description 'Get repository list ordered by MRU first' -a history_file
    set -l all_list (__ghq_fzf_get_list)
    if test (count $all_list) -eq 0
        return 0
    end

    if not test -f "$history_file"
        string join \n $all_list
        return 0
    end

    set -l hist_rev (awk '{a[NR]=$0} END {for (i=NR; i>=1; i--) print a[i]}' "$history_file" 2>/dev/null; or true)
    if test (count $hist_rev) -eq 0
        string join \n $all_list
        return 0
    end

    set -l valid_hist (awk 'NR==FNR {a[$0]=1; next} ($0 in a)' (string join \n $all_list | psub) (string join \n $hist_rev | psub))
    set -l remaining
    if test (count $valid_hist) -gt 0
        set remaining (awk 'NR==FNR {a[$0]=1; next} !($0 in a)' (string join \n $valid_hist | psub) (string join \n $all_list | psub))
    else
        set remaining $all_list
    end

    if test (count $valid_hist) -gt 0; and test (count $remaining) -gt 0
        string join \n $valid_hist $remaining
    else if test (count $valid_hist) -gt 0
        string join \n $valid_hist
    else
        string join \n $remaining
    end
end

function __ghq_fzf_render_preview --description 'Render preview window for fzf showing git status and file listing' -a repo_rel
    set -l ghq_root (__ghq_fzf_get_root)
    set -l full_path "$ghq_root/$repo_rel"

    if not test -d "$full_path"
        echo "Directory not found: $full_path" >&2
        return 1
    end

    set -l git_stat (git -C "$full_path" status -s 2>/dev/null; or true)
    if test (count $git_stat) -gt 0; and test -n "$git_stat[1]"
        string join \n $git_stat
        echo ""
    end

    set -l preview_cols "$FZF_PREVIEW_COLUMNS"
    test -z "$preview_cols"; and set preview_cols "$COLUMNS"
    test -z "$preview_cols"; and set preview_cols 80

    if type -q eza
        if test $preview_cols -ge 75
            eza --color=always -la --icons --time-style=long-iso "$full_path"
        else
            eza --color=always -1a --icons "$full_path"
        end
    else
        ls -la "$full_path"
    end
end

function __ghq_fzf_open_in_editor --description 'Open selected repository in Neovim or system default application' -a repo_rel history_file
    set -l ghq_root (__ghq_fzf_get_root)
    set -l full_path "$ghq_root/$repo_rel"

    __ghq_fzf_save_history "$repo_rel" "$history_file"

    if type -q nvim
        nvim "$full_path"
    else
        open "$full_path"
    end
end

function ghq_fzf --description 'Interactive repository selector using ghq and fzf with MRU history support'
    set -l history_file "$GHQ_FZF_HISTORY_FILE"
    if test -z "$history_file"
        set -l cache_root "$XDG_CACHE_HOME"
        if test -z "$cache_root"
            set cache_root "$HOME/.cache"
        end
        set history_file "$cache_root/ghq_fzf/history"
    end

    set -l mode "select"

    set -l i 1
    while test $i -le (count $argv)
        switch $argv[$i]
            case --preview
                set -l next (math $i + 1)
                __ghq_fzf_render_preview $argv[$next]
                return 0
            case --open
                set -l next (math $i + 1)
                __ghq_fzf_open_in_editor $argv[$next] "$history_file"
                return 0
            case --editor
                set mode "editor"
            case '*'
                # Ignore unknown positional args
        end
        set i (math $i + 1)
    end

    set -l list (__ghq_fzf_get_ordered_list "$history_file")
    if test (count $list) -eq 0
        echo "No repositories found." >&2
        return 1
    end

    if not type -q fzf
        echo "Error: fzf is not installed." >&2
        return 1
    end

    set -l self_bin (__ghq_fzf_get_self_bin)

    set -l selected_rel (printf '%s\n' $list | fzf \
        --prompt="Repo> " \
        --header="Enter: Select | Ctrl-O: Open in Neovim" \
        --preview="fish \"$self_bin\" --preview {}" \
        --preview-window="right:50%" \
        --bind="ctrl-o:execute(fish \"$self_bin\" --open {})+accept"
    )
    if test $status -ne 0; or test (count $selected_rel) -eq 0; or test -z "$selected_rel"
        return 1
    end

    __ghq_fzf_save_history "$selected_rel" "$history_file"

    set -l ghq_root (__ghq_fzf_get_root)
    set -l selected_full "$ghq_root/$selected_rel"

    if test "$mode" = "editor"
        __ghq_fzf_open_in_editor "$selected_rel" "$history_file"
    else
        echo "$selected_full"
    end
end

if test (count $argv) -gt 0
    ghq_fzf $argv
end
