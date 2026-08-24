#
# Environment configuration for zsh, executed for all shell invocations.
#

# Avoid path_helper reordering PATH
setopt no_global_rcs

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-${HOME}/.local/state}"

export ZDOTDIR="${XDG_CONFIG_HOME}/zsh"

if [[ -f "${HOME}/.cargo/env" ]]; then
  . "${HOME}/.cargo/env"
fi

if [[ -f "${HOME}/.vite-plus/env" ]]; then
  . "${HOME}/.vite-plus/env"
fi

if [[ -f "${HOME}/.zshenv.local" ]]; then
  . "${HOME}/.zshenv.local"
fi
