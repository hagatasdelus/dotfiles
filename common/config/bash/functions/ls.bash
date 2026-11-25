function ls() {
    if command -v eza >/dev/null 2>&1; then
        command eza -l --header --icons=auto "$@"
    else
        command ls -lhAFG "$@"
    fi
}

