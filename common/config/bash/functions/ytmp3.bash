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
