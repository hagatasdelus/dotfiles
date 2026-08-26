function _fzf_ghq --description 'Fish keybinding widget to select repository and cd'
    set -l repo_dir (ghq_fzf)
    if test -n "$repo_dir"; and test -d "$repo_dir"
        commandline -r "cd (string escape -- $repo_dir)"
        commandline -f execute
    end
    commandline -f repaint
end
