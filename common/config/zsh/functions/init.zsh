#
# Loader for modular function definitions in zsh.
#

typeset current_dir="${${(%):-%N}:A:h}"

. "${current_dir}/rm.zsh"
. "${current_dir}/ghq_fzf.zsh"
. "${current_dir}/history_edit.zsh"
