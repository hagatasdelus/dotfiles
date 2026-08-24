function fish_prompt --description 'Pure-style prompt with git branch & status'

    set -l last_status $status

    # Newline before prompt (except at the very top of buffer)
    echo ''

    # Current working directory (blue)
    set_color 5fafff --bold
    echo -n (prompt_pwd)
    set_color normal

    # Git status (grey/yellow/magenta)
    if type -q fish_git_prompt
        set -g __fish_git_prompt_showdirtystate 1
        set -g __fish_git_prompt_showuntrackedfiles 1
        set -g __fish_git_prompt_showupstream informative
        set -g __fish_git_prompt_char_dirtystate '*'
        set -g __fish_git_prompt_char_stagedstate '+'
        set -g __fish_git_prompt_char_untrackedfiles '?'
        set -g __fish_git_prompt_char_upstream_ahead ' ^'
        set -g __fish_git_prompt_char_upstream_behind ' v'
        set -g __fish_git_prompt_color_branch magenta --bold
        set -g __fish_git_prompt_color_dirtystate red
        set -g __fish_git_prompt_color_stagedstate green

        set_color normal
        echo -n (fish_git_prompt)
    end

    # Prompt symbol on new line (magenta on success, red on failure)
    echo ''
    if test $last_status -eq 0
        set_color magenta --bold
    else
        set_color red --bold
    end
    echo -n '❯ '
    set_color normal
end
