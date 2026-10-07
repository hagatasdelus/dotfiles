#
# History editor utility function for bash.
#

# Edit shell history file directly in EDITOR and reload history.
function history_edit() {
  fc -W
  "${EDITOR:-nvim}" "${HISTFILE}"
  fc -R
}
