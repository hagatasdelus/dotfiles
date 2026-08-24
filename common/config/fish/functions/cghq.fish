function cghq --description 'Interactive repository change directory'
    set -l repo_dir (ghq_fzf $argv)
    if test -n "$repo_dir"; and test -d "$repo_dir"
        cd "$repo_dir"
    end
end
