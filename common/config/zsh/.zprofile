#
# Login shell configuration for zsh
#

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-${HOME}/.local/state}"

export TERMINFO="/usr/share/terminfo/"
export SQLITE_HISTORY="${XDG_STATE_HOME}/sqlite_history"
export PYTHON_HISTORY="${XDG_STATE_HOME}/python_history"

typeset arch
arch="$(uname -m)"
typeset brew_bin=""
if [[ "${arch}" == "arm64" && -x "/opt/homebrew/bin/brew" ]]; then
  brew_bin="/opt/homebrew/bin/brew"
elif [[ "${arch}" == "x86_64" && -x "/usr/local/bin/brew" ]]; then
  brew_bin="/usr/local/bin/brew"
fi

if [[ -n "${brew_bin}" ]]; then
  typeset brew_cache="${XDG_CACHE_HOME}/zsh/profile/brew.zsh"
  if [[ ! -d "${XDG_CACHE_HOME}/zsh/profile" ]]; then
    mkdir -p "${XDG_CACHE_HOME}/zsh/profile"
  fi
  if [[ ! -f "${brew_cache}" || "${brew_bin}" -nt "${brew_cache}" ]]; then
    "${brew_bin}" shellenv > "${brew_cache}" 2>/dev/null
    zcompile "${brew_cache}" 2>/dev/null || true
  fi
  . "${brew_cache}"
fi

typeset current_dir="${${(%):-%N}:A:h}"
if [[ -f "${current_dir}/path.zsh" ]]; then
  . "${current_dir}/path.zsh"
elif [[ -f "${XDG_CONFIG_HOME}/zsh/path.zsh" ]]; then
  . "${XDG_CONFIG_HOME}/zsh/path.zsh"
fi
