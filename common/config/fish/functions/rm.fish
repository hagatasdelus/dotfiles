function rm --description 'Safe wrapper for rm to protect critical directories'
    set -l protected_paths \
        "/" \
        "/System" \
        "/Library" \
        "/Applications" \
        "/Users" \
        "/Volumes" \
        "/bin" \
        "/sbin" \
        "/usr" \
        "/usr/local" \
        "/opt" \
        "/opt/homebrew" \
        "/etc" \
        "/var" \
        "/private" \
        "$HOME" \
        "$HOME/Desktop" \
        "$HOME/Documents" \
        "$HOME/Downloads" \
        "$HOME/Library" \
        "$HOME/Library/Application Support" \
        "$HOME/Library/Caches" \
        "$HOME/Pictures" \
        "$HOME/Movies" \
        "$HOME/Music" \
        "$HOME/.ssh" \
        "$HOME/.gnupg" \
        "$HOME/.config" \
        "$HOME/.local" \
        "$HOME/.local/share" \
        "$HOME/.local/state"

    for arg in $argv
        if string match -q -- '-*' "$arg"
            continue
        end

        set -l abs_path (realpath "$arg" 2>/dev/null)
        if test -z "$abs_path"
            set abs_path "$arg"
        end

        if test "$abs_path" != "/"
            set abs_path (string replace -r '/+$' '' -- "$abs_path")
        end

        for protected in $protected_paths
            if test "$abs_path" = "$protected"
                echo "Error: Blocked: Deletion of a protected directory was attempted." >&2
                echo "  Target:   '$arg'" >&2
                echo "  Resolved: '$abs_path'" >&2
                echo "Hint: To bypass this safeguard, execute '/bin/rm' directly." >&2
                return 1
            end
        end
    end

    command rm $argv
end
