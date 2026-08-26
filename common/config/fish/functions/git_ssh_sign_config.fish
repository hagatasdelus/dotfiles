function git_ssh_sign_config --description 'Configure Git SSH signing key if GIT_SSH_KEY is set'
    if not set -q GIT_SSH_KEY; or test -z "$GIT_SSH_KEY"
        return 0
    end

    set -l current_key (git config --local user.signingKey 2>/dev/null)

    if test "$current_key" != "$GIT_SSH_KEY"
        git config user.signingKey "$GIT_SSH_KEY"
    end
end
