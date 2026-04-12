function rm() {
  local protected_paths=(
    "/"
    "$HOME"
    "$HOME/Library"
    "$HOME/Documents"
    "$HOME/Desktop"
    "$HOME/Downloads"
  )

  for arg in "$@"; do
    [[ "$arg" == -* ]] && continue

    local abs_path
    abs_path=$(realpath "$arg" 2>/dev/null)

    if [[ -z "$abs_path" ]]; then
      abs_path="$arg"
    fi

    abs_path="${abs_path%/}"

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
