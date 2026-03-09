function history-edit() {
    fc -W
    ${EDITOR:-nvim} "${HISTFILE}"
    fc -R
}

function course_setup() {
    COMMAND_LINE="$@"
    NUMBER_OF_ARGUMENTS=$#

    if [ ${NUMBER_OF_ARGUMENTS} -lt 1 ]; then
        echo "Command Failed: Specify one or more course names." >&2
        exit 1
    fi

    for COURSE in ${COMMAND_LINE}; do
        mkdir -p "${COURSE}/lectures" "${COURSE}/reports" "${COURSE}/tests" "${COURSE}/pastexams"

        for i in $(seq -f '%02g' 1 15); do
            mkdir -p "${COURSE}/lectures/${i}"
        done
        echo "Course Setup Done >> ${COURSE}"
    done

    exit 0
}

function git_ssh_sign_config() {
    if [ -z "$GIT_SSH_KEY" ]; then
        echo "GIT_SSH_KEY not found"
        return
    fi

    local current_key=$(git config --local user.signingKey 2>/dev/null)

    if [ "$current_key" != "$GIT_SSH_KEY" ]; then
        git config user.signingKey "$GIT_SSH_KEY"
    fi
}

function __after_cd() {
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

# ytmp3 <URL> [quality_kbps]
function ytmp3() {
    local save_dir="$HOME/__gi/sounds"

    local url=$1
    local quality=${2:-64} # Default: 64kbps

    mkdir -p "$save_dir"

    uvx yt-dlp \
        -x \
        --audio-format mp3 \
        --audio-quality "${quality}K" \
        --embed-metadata \
        --no-mtime \
        -P "$save_dir" \
        -o "%(title)s.%(ext)s" \
        "$url"
}
