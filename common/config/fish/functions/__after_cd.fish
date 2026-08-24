function __after_cd --description 'Hook executed after directory change'
    if status is-interactive
        if type -q eza
            eza -l --header --icons
        else
            ls -lhA
        end
    end

    if test -d .git
        git_ssh_sign_config
    end
end
