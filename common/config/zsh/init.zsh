#
# Tool integrations, environment variables, and cached evaluation for zsh.
#

export LANGUAGE="en_US:en"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export PLATFORM="$(uname)"

export EDITOR="nvim"
export VISUAL="nvim"
export GIT_EDITOR="nvim"

export _JAVA_OPTIONS="-Dfile.encoding=UTF-8"
if [[ -x "/usr/libexec/java_home" ]]; then
  export JAVA_HOME="$(/usr/libexec/java_home -v "23" 2>/dev/null || /usr/libexec/java_home 2>/dev/null)"
fi

if [[ -d "/usr/local/ant" ]]; then
  export ANT_HOME="/usr/local/ant"
  export ANT_OPTS="-Dfile.encoding=UTF-8 -Xmx512m -Xss256k"
fi

export HOMEBREW_NO_EMOJI=1
export HOMEBREW_FORBIDDEN_FORMULAE="node python python3 pip npm pnpm yarn go"

export DENO_INSTALL="${HOME}/.deno"
if [[ -f "${HOME}/.deno/env" ]]; then
  . "${HOME}/.deno/env"
fi

if [[ -d "${HOME}/.local/share/pnpm" ]]; then
  export PNPM_HOME="${HOME}/.local/share/pnpm"
  path=("${PNPM_HOME}" "${path[@]}")
fi

export CLICOLOR=1
export LSCOLORS="gxfxcxdxbxegedabagacad"

if command -v git >/dev/null 2>&1; then
  typeset ghq_root
  ghq_root="$(git config ghq.root 2>/dev/null)"
  if [[ -n "${ghq_root}" ]]; then
    export GHROOT="${ghq_root}/github.com"
  fi
fi

export CACHE_PROFILE="${XDG_CACHE_HOME:-${HOME}/.cache}/zsh/profile"
mkdir -p "${CACHE_PROFILE}"

# Clear profile cache directory.
function cache::clear() {
  rm -rf "${CACHE_PROFILE}"
  mkdir -p "${CACHE_PROFILE}"
}

# Execute a command, cache its stdout, zcompile, and source it.
# Arguments:
#   name: Identifier for the cache file.
#   bin: Path to the binary executable to check for timestamp updates.
#   ...: Command and arguments to execute.
function cache::eval() {
  local name="$1"
  local bin="$2"
  shift 2
  local cache_file="${CACHE_PROFILE}/${name}.zsh"

  if [[ ! -f "${cache_file}" || ( -n "${bin}" && -f "${bin}" && "${bin}" -nt "${cache_file}" ) ]]; then
    "$@" > "${cache_file}" 2>/dev/null
    zcompile "${cache_file}" 2>/dev/null || true
  fi

  if [[ -f "${cache_file}" ]]; then
    . "${cache_file}"
  fi
}

if command -v direnv >/dev/null 2>&1; then
  cache::eval "direnv" "$(command -v direnv)" direnv hook zsh
fi

if command -v mise >/dev/null 2>&1; then
  cache::eval "mise" "$(command -v mise)" mise activate zsh
fi

if command -v git-wt >/dev/null 2>&1; then
  cache::eval "git-wt" "$(command -v git-wt)" git wt --init zsh
fi

if command -v pip >/dev/null 2>&1; then
  cache::eval "pip" "$(command -v pip)" pip completion --zsh
fi

if command -v pip3 >/dev/null 2>&1; then
  cache::eval "pip3" "$(command -v pip3)" pip3 completion --zsh
fi

if [[ -d "/Applications/Docker.app" ]]; then
  alias docker="/Applications/Docker.app/Contents/Resources/bin/docker"
fi
if command -v docker >/dev/null 2>&1; then
  cache::eval "docker" "$(command -v docker)" docker completion zsh
fi

if command -v kubectl >/dev/null 2>&1; then
  cache::eval "kubectl" "$(command -v kubectl)" kubectl completion zsh
fi

if command -v deno >/dev/null 2>&1; then
  cache::eval "deno" "$(command -v deno)" deno completions zsh
fi
