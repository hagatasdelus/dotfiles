# Interactive-only setup for fish

if status is-interactive
    set -g fish_greeting ''

    # Disable Ctrl-S / Ctrl-Q freeze
    stty stop undef 2>/dev/null
    stty start undef 2>/dev/null

    if type -q fzf
        set -gx FZF_DEFAULT_OPTS '
            --exact
            --border
            --reverse
            --height=40%
            --bind=ctrl-t:up,ctrl-g:down
        '
        if type -q fd
            set -gx FZF_DEFAULT_COMMAND 'fd --type f'
        else if type -q rg
            set -gx FZF_DEFAULT_COMMAND 'rg --files --hidden --glob "!.git"'
        end
    end

    # Tool hooks and completions with caching (following ryoppippi & lambdalisue patterns)
    set -l fish_cache_dir "$XDG_CACHE_HOME/fish/profile"
    mkdir -p "$fish_cache_dir"

    # Mise
    if type -q mise
        set -l mise_cache "$fish_cache_dir/mise.fish"
        if not test -f "$mise_cache"
            mise activate fish > "$mise_cache" 2>/dev/null
        end
        source "$mise_cache"
    end

    # Direnv
    if type -q direnv
        set -l direnv_cache "$fish_cache_dir/direnv.fish"
        if not test -f "$direnv_cache"
            direnv hook fish > "$direnv_cache" 2>/dev/null
        end
        source "$direnv_cache"
    end

    # git-wt
    if type -q git-wt
        set -l gitwt_cache "$fish_cache_dir/git-wt.fish"
        if not test -f "$gitwt_cache"; or test (command -v git-wt) -nt "$gitwt_cache"
            git wt --init fish > "$gitwt_cache" 2>/dev/null
        end
        source "$gitwt_cache"
    end

    # Docker completion
    if test -d "/Applications/Docker.app"
        alias docker="/Applications/Docker.app/Contents/Resources/bin/docker"
    end
    if type -q docker
        set -l docker_cache "$fish_cache_dir/docker.fish"
        if not test -f "$docker_cache"
            docker completion fish > "$docker_cache" 2>/dev/null
        end
        source "$docker_cache"
    end

    # kubectl completion
    if type -q kubectl
        set -l kubectl_cache "$fish_cache_dir/kubectl.fish"
        if not test -f "$kubectl_cache"
            kubectl completion fish > "$kubectl_cache" 2>/dev/null
        end
        source "$kubectl_cache"
    end

    # Deno completion
    if type -q deno
        set -l deno_cache "$fish_cache_dir/deno.fish"
        if not test -f "$deno_cache"
            deno completions fish > "$deno_cache" 2>/dev/null
        end
        source "$deno_cache"
    end

    # Trigger __after_cd on directory change
    function __on_pwd_change --on-variable PWD --description 'Execute __after_cd on directory change'
        __after_cd
    end
end
