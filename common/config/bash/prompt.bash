#
# Minimal and fast two-line prompt for bash.
#

_byaku_color_red="$(tput setaf 1 2>/dev/null || echo '')"
_byaku_color_green="$(tput setaf 2 2>/dev/null || echo '')"
_byaku_color_yellow="$(tput setaf 3 2>/dev/null || echo '')"
_byaku_color_blue="$(tput setaf 4 2>/dev/null || echo '')"
_byaku_color_magenta="$(tput setaf 5 2>/dev/null || echo '')"
_byaku_color_cyan="$(tput setaf 6 2>/dev/null || echo '')"
_byaku_color_white="$(tput setaf 7 2>/dev/null || echo '')"
_byaku_color_gray="$(tput setaf 8 2>/dev/null || echo '')"
_byaku_color_reset="$(tput sgr0 2>/dev/null || echo '')"

BYAKU_PROMPT_SYMBOL="${BYAKU_PROMPT_SYMBOL:-❯}"
BYAKU_CMD_MAX_EXEC_TIME="${BYAKU_CMD_MAX_EXEC_TIME:-5}"
BYAKU_GIT_DIRTY="${BYAKU_GIT_DIRTY:-*}"

_byaku_cmd_start=""
_byaku_cmd_duration=""
_byaku_has_git=0
_byaku_preexec_ready=0

# Check if git executable is available in PATH.
function _byaku_init_git_check() {
  if command -v git &>/dev/null; then
    _byaku_has_git=1
  else
    _byaku_has_git=0
  fi
}

# Format seconds into a human-readable duration string.
# Arguments:
#   total_seconds: Duration in seconds.
# Outputs:
#   Formatted duration string to stdout.
function _byaku_format_duration() {
  local total_seconds="$1"
  local result=""

  local days=$(( total_seconds / 86400 ))
  local hours=$(( (total_seconds % 86400) / 3600 ))
  local minutes=$(( (total_seconds % 3600) / 60 ))
  local seconds=$(( total_seconds % 60 ))

  (( days > 0 )) && result+="${days}d "
  (( hours > 0 )) && result+="${hours}h "
  (( minutes > 0 )) && result+="${minutes}m "
  result+="${seconds}s"

  echo "${result}"
}

# Check if current working directory is inside a Git repository.
# Returns:
#   0 if in git repo, 1 otherwise.
function _byaku_is_git_repo() {
  local dir="${PWD}"
  while [[ -n "${dir}" ]]; do
    [[ -d "${dir}/.git" ]] && return 0
    [[ "${dir}" == "/" ]] && break
    dir="${dir%/*}"
    [[ -z "${dir}" ]] && dir="/"
  done
  return 1
}

# Extract branch and dirty status from Git in a single call.
# Outputs:
#   Formatted colored git branch string to stdout.
function _byaku_git_info() {
  _byaku_is_git_repo || return 0

  local git_status
  git_status="$(git status --porcelain --branch 2>/dev/null)" || return 0

  local branch=""
  local dirty=""
  local first_line="${git_status%%$'\n'*}"

  if [[ "${first_line}" =~ ^##\ No\ commits\ yet\ on\ ([^.[:space:]]+) ]]; then
    branch="${BASH_REMATCH[1]}"
  elif [[ "${first_line}" =~ ^##\ HEAD\ \(no\ branch\) ]]; then
    branch="$(git rev-parse --short HEAD 2>/dev/null)"
  elif [[ "${first_line}" =~ ^##\ ([^.[:space:]]+) ]]; then
    branch="${BASH_REMATCH[1]}"
  else
    return 0
  fi

  local rest="${git_status#*$'\n'}"
  [[ "${rest}" != "${git_status}" && -n "${rest}" ]] && dirty="${BYAKU_GIT_DIRTY}"

  if [[ -n "${dirty}" ]]; then
    echo " ${_byaku_color_red}${branch}${dirty}${_byaku_color_reset}"
  else
    echo " ${_byaku_color_green}${branch}${_byaku_color_reset}"
  fi
}

# DEBUG trap hook to record command start time.
function _byaku_preexec() {
  [[ "${_byaku_preexec_ready}" != "1" ]] && return 0
  [[ -z "${BASH_COMMAND}" ]] && return 0
  [[ "${BASH_COMMAND}" == "_byaku_prompt_command" ]] && return 0

  _byaku_cmd_start="${EPOCHSECONDS:-$(date +%s)}"
}

# Calculate elapsed execution time for completed command.
function _byaku_precmd() {
  _byaku_cmd_duration=""
  [[ -z "${_byaku_cmd_start}" ]] && return 0

  local now="${EPOCHSECONDS:-$(date +%s)}"
  local elapsed=$(( now - _byaku_cmd_start ))

  if (( elapsed > BYAKU_CMD_MAX_EXEC_TIME )); then
    _byaku_cmd_duration="$(_byaku_format_duration "${elapsed}")"
  fi

  _byaku_cmd_start=""
}

# Construct and set PS1/PS2 prompt and window title.
function _byaku_prompt_command() {
  local exit_status=$?

  _byaku_preexec_ready=0
  _byaku_precmd

  local user_host=""
  local path_info=""
  local git_info=""
  local venv_info=""
  local duration_info=""

  if [[ -n "${SSH_CLIENT}" ]] || [[ -n "${SSH_TTY}" ]]; then
    user_host="${_byaku_color_gray}${USER}${_byaku_color_reset}@${_byaku_color_yellow}${HOSTNAME%%.*}${_byaku_color_reset}:"
  fi

  path_info="${_byaku_color_white}\w${_byaku_color_reset}"

  if (( _byaku_has_git )); then
    git_info="$(_byaku_git_info)"
  fi

  if [[ -n "${VIRTUAL_ENV}" ]]; then
    venv_info=" ${_byaku_color_gray}(${VIRTUAL_ENV##*/})${_byaku_color_reset}"
  fi

  if [[ -n "${_byaku_cmd_duration}" ]]; then
    duration_info=" ${_byaku_color_yellow}${_byaku_cmd_duration}${_byaku_color_reset}"
  fi

  local symbol_color
  if (( exit_status == 0 )); then
    symbol_color="${_byaku_color_cyan}"
  else
    symbol_color="${_byaku_color_red}"
  fi

  local first_line="${user_host}${path_info}${git_info}${venv_info}${duration_info}"
  local second_line="\[${symbol_color}\]${BYAKU_PROMPT_SYMBOL}\[${_byaku_color_reset}\] "

  PS1=$'\n'"${first_line}"$'\n'"${second_line}"
  PS2="\[${_byaku_color_cyan}\]${BYAKU_PROMPT_SYMBOL}\[${_byaku_color_reset}\] "

  local title="${PWD##*/}"
  [[ -z "${title}" ]] && title="/"
  if [[ -n "${SSH_CLIENT}" ]] || [[ -n "${SSH_TTY}" ]]; then
    title="${title} — ${HOSTNAME%%.*}"
  fi
  echo -ne "\033]0;${title}\007"

  _byaku_preexec_ready=1
}

_byaku_init_git_check
_byaku_preexec_ready=0

trap '_byaku_preexec' DEBUG
PROMPT_COMMAND+=(_byaku_prompt_command)
