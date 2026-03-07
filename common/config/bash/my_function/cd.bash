function cd() {
    builtin cd "$@" && {
        if is_interactive; then
            if command -v eza >/dev/null 2>&1; then
                command eza -l --header --icons
            else
                command ls -lhAFG
            fi
        fi
        if [ -d .git ]; then
            git_ssh_sign_config
        fi
    }
}
