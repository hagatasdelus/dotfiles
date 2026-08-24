#
# Core shell functions and directory hooks for zsh.
#

typeset current_dir="${${(%):-%N}:A:h}"
. "${current_dir}/functions/init.zsh"

function git_ssh_sign_config() {
  if [[ -z "${GIT_SSH_KEY}" ]]; then
    return 0
  fi

  local current_key
  current_key="$(git config --local user.signingKey 2>/dev/null || true)"

  if [[ "${current_key}" != "${GIT_SSH_KEY}" ]]; then
    git config user.signingKey "${GIT_SSH_KEY}"
  fi
}

# Hook function executed after directory change (chpwd)
function __after_cd() {
  if [[ -o interactive ]]; then
    if command -v eza >/dev/null 2>&1; then
      command eza -l --header --icons
    else
      command ls -lhAFG
    fi
  fi

  if [[ -d ".git" ]]; then
    git_ssh_sign_config
  fi
}
