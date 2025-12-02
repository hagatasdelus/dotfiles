function cd() {
    builtin cd "$@" && {
        if command -v eza >/dev/null 2>&1; then
            eza -l --header --icons
        else
            ls -l
        fi
    }
}
