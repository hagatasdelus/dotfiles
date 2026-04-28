#!/usr/bin/env bash
#
# byaku - Pretty, minimal and fast Bash prompt
#
# Inspired by: https://github.com/sindresorhus/pure
#
# Installation:
#   source /path/to/byaku.bash
#
# Customization (set before sourcing):
#   export BYAKU_PROMPT_SYMBOL="→"
#   export BYAKU_CMD_MAX_EXEC_TIME=10
#   export BYAKU_GIT_DIRTY="!"
#

# =============================================================================
# Color Definitions (cached at startup for performance)
# =============================================================================

# Cache tput output to avoid repeated calls
# Graceful degradation: empty string if tput fails
_byaku_color_red="$(tput setaf 1 2>/dev/null || echo '')"
_byaku_color_green="$(tput setaf 2 2>/dev/null || echo '')"
_byaku_color_yellow="$(tput setaf 3 2>/dev/null || echo '')"
_byaku_color_blue="$(tput setaf 4 2>/dev/null || echo '')"
_byaku_color_magenta="$(tput setaf 5 2>/dev/null || echo '')"
_byaku_color_cyan="$(tput setaf 6 2>/dev/null || echo '')"
_byaku_color_white="$(tput setaf 7 2>/dev/null || echo '')"
_byaku_color_gray="$(tput setaf 8 2>/dev/null || echo '')"
_byaku_color_reset="$(tput sgr0 2>/dev/null || echo '')"

# =============================================================================
# User Configuration (environment variable overrides)
# =============================================================================

# Prompt symbol (default: ❯)
BYAKU_PROMPT_SYMBOL="${BYAKU_PROMPT_SYMBOL:-❯}"

# Command execution time threshold in seconds (default: 5)
BYAKU_CMD_MAX_EXEC_TIME="${BYAKU_CMD_MAX_EXEC_TIME:-5}"

# Git dirty indicator symbol (default: *)
BYAKU_GIT_DIRTY="${BYAKU_GIT_DIRTY:-*}"

# =============================================================================
# Internal State Variables
# =============================================================================

_byaku_cmd_start=""
_byaku_cmd_duration=""
_byaku_has_git=""  # Cached git availability

# =============================================================================
# Utility Functions
# =============================================================================

# Check if git is available (cached at init time)
_byaku_init_git_check() {
    if command -v git &>/dev/null; then
        _byaku_has_git=1
    else
        _byaku_has_git=0
    fi
}

# Convert seconds to human-readable format
# Usage: _byaku_format_duration 3661
# Output: "1h 1m 1s"
_byaku_format_duration() {
    local total_seconds=$1
    local result=""
    
    local days=$((total_seconds / 86400))
    local hours=$(((total_seconds % 86400) / 3600))
    local minutes=$(((total_seconds % 3600) / 60))
    local seconds=$((total_seconds % 60))
    
    ((days > 0)) && result+="${days}d "
    ((hours > 0)) && result+="${hours}h "
    ((minutes > 0)) && result+="${minutes}m "
    result+="${seconds}s"
    
    echo "$result"
}

# =============================================================================
# Git Functions
# =============================================================================

# Check if we're in a git repository (fast fs check, no git command)
_byaku_is_git_repo() {
    local dir="$PWD"
    while [[ -n "$dir" ]]; do
        [[ -d "$dir/.git" ]] && return 0
        # Move to parent directory
        [[ "$dir" == "/" ]] && break
        dir="${dir%/*}"
        [[ -z "$dir" ]] && dir="/"
    done
    return 1
}

# Get git repository information
# Output: formatted git info string or empty if not in a git repo
_byaku_git_info() {
    # Fast fs check first (avoids spawning git process in non-git dirs)
    _byaku_is_git_repo || return
    
    # Get all info in ONE git command: branch + dirty status
    # Format: "## branch...remote" or "## No commits yet on branch"
    local git_status branch dirty=""
    git_status="$(git status --porcelain --branch 2>/dev/null)" || return
    
    # Parse branch from first line
    local first_line="${git_status%%$'\n'*}"
    if [[ "$first_line" =~ ^##\ No\ commits\ yet\ on\ ([^.[:space:]]+) ]]; then
        # New repo with no commits: "## No commits yet on branch...remote"
        branch="${BASH_REMATCH[1]}"
    elif [[ "$first_line" =~ ^##\ HEAD\ \(no\ branch\) ]]; then
        # Detached HEAD
        branch="$(git rev-parse --short HEAD 2>/dev/null)"
    elif [[ "$first_line" =~ ^##\ ([^.[:space:]]+) ]]; then
        # Normal branch: "## branch...origin/branch"
        branch="${BASH_REMATCH[1]}"
    else
        return
    fi
    
    # Check for dirty status (any line after the first indicates changes)
    local rest="${git_status#*$'\n'}"
    [[ "$rest" != "$git_status" && -n "$rest" ]] && dirty="${BYAKU_GIT_DIRTY}"
    
    # Format output with color
    if [[ -n "$dirty" ]]; then
        echo " ${_byaku_color_red}${branch}${dirty}${_byaku_color_reset}"
    else
        echo " ${_byaku_color_green}${branch}${_byaku_color_reset}"
    fi
}

# =============================================================================
# Timing Functions
# =============================================================================

# Flag to control preexec behavior (avoid running during prompt generation)
_byaku_preexec_ready=1

# Called before command execution (via DEBUG trap)
_byaku_preexec() {
    # Skip if preexec is not ready (during prompt generation)
    [[ "$_byaku_preexec_ready" != "1" ]] && return
    
    # Only record if we're about to execute a real command
    # BASH_COMMAND is empty for empty lines
    [[ -z "${BASH_COMMAND}" ]] && return
    
    # Don't record for prompt command itself
    [[ "${BASH_COMMAND}" == "_byaku_prompt_command" ]] && return
    
    # Use EPOCHSECONDS if available (Bash 4.2+), otherwise fall back to date
    _byaku_cmd_start="${EPOCHSECONDS:-$(date +%s)}"
}

# Called before prompt display
_byaku_precmd() {
    _byaku_cmd_duration=""
    
    # Skip if no start time recorded
    [[ -z "$_byaku_cmd_start" ]] && return
    
    # Calculate elapsed time
    local now="${EPOCHSECONDS:-$(date +%s)}"
    local elapsed=$((now - _byaku_cmd_start))
    
    # Only show if above threshold
    if ((elapsed > BYAKU_CMD_MAX_EXEC_TIME)); then
        _byaku_cmd_duration="$(_byaku_format_duration "$elapsed")"
    fi
    
    # Reset start time
    _byaku_cmd_start=""
}

# =============================================================================
# Main Prompt Function
# =============================================================================

_byaku_prompt_command() {
    # Capture exit status FIRST (before any other command overwrites it)
    local exit_status=$?
    
    # Disable preexec during prompt generation to avoid unnecessary calls
    _byaku_preexec_ready=0
    
    # Calculate command duration
    _byaku_precmd
    
    # Build prompt components
    local user_host=""
    local path_info=""
    local git_info=""
    local venv_info=""
    local duration_info=""
    
    # SSH detection: show user@host only when connected via SSH
    if [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]; then
        user_host="${_byaku_color_gray}${USER}${_byaku_color_reset}@${_byaku_color_yellow}${HOSTNAME%%.*}${_byaku_color_reset}:"
    fi
    
    # Current directory (use \w for path with ~ substitution)
    path_info="${_byaku_color_white}\w${_byaku_color_reset}"
    
    # Git information (only if git is available - uses cached check)
    if ((_byaku_has_git)); then
        git_info="$(_byaku_git_info)"
    fi
    
    # Python virtualenv (use parameter expansion instead of basename)
    if [[ -n "$VIRTUAL_ENV" ]]; then
        venv_info=" ${_byaku_color_gray}(${VIRTUAL_ENV##*/})${_byaku_color_reset}"
    fi
    
    # Command duration (if threshold exceeded)
    if [[ -n "$_byaku_cmd_duration" ]]; then
        duration_info=" ${_byaku_color_yellow}${_byaku_cmd_duration}${_byaku_color_reset}"
    fi
    
    # Prompt symbol color based on exit status
    local symbol_color
    if ((exit_status == 0)); then
        symbol_color="${_byaku_color_cyan}"
    else
        symbol_color="${_byaku_color_red}"
    fi
    
    # Build the prompt
    # Line 1: [user@host:]path [git] [venv] [duration]
    # Line 2: ❯ (colored based on exit status)
    local first_line="${user_host}${path_info}${git_info}${venv_info}${duration_info}"
    local second_line="\[${symbol_color}\]${BYAKU_PROMPT_SYMBOL}\[${_byaku_color_reset}\] "
    
    PS1="\n${first_line}\n${second_line}"
    PS2="\[${_byaku_color_cyan}\]${BYAKU_PROMPT_SYMBOL}\[${_byaku_color_reset}\] "
    
    # Set terminal title (use parameter expansion instead of basename)
    local title="${PWD##*/}"
    [[ -z "$title" ]] && title="/"
    if [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]; then
        title="${title} — ${HOSTNAME%%.*}"
    fi
    echo -ne "\033]0;${title}\007"
    
    # Re-enable preexec for next command
    _byaku_preexec_ready=1
}

# =============================================================================
# Setup
# =============================================================================

# Initialize cached checks
_byaku_init_git_check

# Initialize preexec ready flag
_byaku_preexec_ready=0

# Set up DEBUG trap for preexec functionality
trap '_byaku_preexec' DEBUG

# Set PROMPT_COMMAND
PROMPT_COMMAND="_byaku_prompt_command"
