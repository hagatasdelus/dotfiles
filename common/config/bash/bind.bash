#
# Key bindings and readline widgets for bash.
#

if [[ $- == *i* ]]; then
  # Readline widget to select ghq repo and insert cd command into prompt line.
  function __ghq_fzf_cd_widget() {
    local repo_dir
    repo_dir="$(ghq_fzf)"
    if [[ -n "${repo_dir}" && -d "${repo_dir}" ]]; then
      READLINE_LINE="cd ${repo_dir}"
      READLINE_POINT=${#READLINE_LINE}
    fi
  }

  bind -x '"\C-g": __ghq_fzf_cd_widget' 2>/dev/null || true
fi
