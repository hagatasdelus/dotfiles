### ls/eza ###
function ls() {
    if command -v eza >/dev/null 2>&1; then
        command eza -l --header --icons "$@"
    else
        command ls -lhAFG "$@"
    fi
}

