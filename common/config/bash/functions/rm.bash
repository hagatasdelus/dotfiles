#
# Safe wrapper for the rm command to protect critical directories from accidental deletion in bash.
#

#######################################
# Remove files or directories with critical path protection.
# Arguments:
#   File or directory paths to delete.
# Outputs:
#   Error message to stderr if deletion of a protected directory is attempted.
# Returns:
#   0 on successful deletion, 1 if blocked or if rm fails.
#######################################
function rm() {
  local protected_paths=(
    "/"
    "/System"
    "/Library"
    "/Applications"
    "/Users"
    "/Volumes"
    "/bin"
    "/sbin"
    "/usr"
    "/usr/local"
    "/opt"
    "/opt/homebrew"
    "/etc"
    "/var"
    "/private"

    "$HOME"
    "$HOME/Desktop"
    "$HOME/Documents"
    "$HOME/Downloads"
    "$HOME/Library"
    "$HOME/Library/Application Support"
    "$HOME/Library/Caches"
    "$HOME/Pictures"
    "$HOME/Movies"
    "$HOME/Music"

    "$HOME/.ssh"
    "$HOME/.gnupg"
    "$HOME/.config"
    "$HOME/.local"
    "$HOME/.local/share"
    "$HOME/.local/state"
  )

  for arg in "$@"; do
    [[ "$arg" == -* ]] && continue

    local abs_path
    abs_path="$(realpath "$arg" 2>/dev/null || true)"

    if [[ -z "$abs_path" ]]; then
      abs_path="$arg"
    fi

    if [[ "$abs_path" != "/" ]]; then
      abs_path="${abs_path%/}"
    fi

    for protected in "${protected_paths[@]}"; do
      if [[ "$abs_path" == "$protected" ]]; then
        echo "Error: Blocked: Deletion of a protected directory was attempted." >&2
        echo "  Target:   '$arg'" >&2
        echo "  Resolved: '$abs_path'" >&2
        echo "Hint: To bypass this safeguard, execute '/bin/rm' directly." >&2
        return 1
      fi
    done
  done

  command rm "$@"
}
