#
# Core shell functions and hooks for bash.
#

. "${BASH_CONFIG_HOME}/functions/init.bash"

# Configure Git SSH signing key locally
function git_ssh_sign_config() {
  if [[ -z "${GIT_SSH_KEY}" ]]; then
    echo "GIT_SSH_KEY not found"
    return 0
  fi

  local current_key
  current_key="$(git config --local user.signingKey 2>/dev/null || true)"

  if [[ "${current_key}" != "${GIT_SSH_KEY}" ]]; then
    git config user.signingKey "${GIT_SSH_KEY}"
  fi
}

# Hook function executed after directory change.
function __after_cd() {
  if is_interactive; then
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
