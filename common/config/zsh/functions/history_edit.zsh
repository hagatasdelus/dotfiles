# Edit shell history file directly in EDITOR and reload history.
function history_edit() {
  fc -W
  "${EDITOR:-nvim}" "${HISTFILE:-${XDG_STATE_HOME}/zsh/history}"
  fc -R
}
