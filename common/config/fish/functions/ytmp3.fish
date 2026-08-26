function ytmp3 --description 'Download YouTube video audio as MP3 via yt-dlp'
    set -l url $argv[1]
    set -l quality $argv[2]
    if test -z "$quality"
        set quality 64
    end

    if test -z "$url"
        echo "Usage: ytmp3 <URL> [quality_kbps]" >&2
        return 1
    end

    set -l save_dir "$HOME/__gi/sounds"
    mkdir -p "$save_dir"

    uvx yt-dlp \
        -x \
        --audio-format mp3 \
        --audio-quality "$quality"K \
        --embed-metadata \
        --no-mtime \
        -P "$save_dir" \
        -o "%(title)s.%(ext)s" \
        "$url"
end
