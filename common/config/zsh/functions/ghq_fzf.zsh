#
# Interactive repository selector using ghq and fzf with MRU history support (zsh-specific).
#

typeset -g _GHQ_FZF_SCRIPT_PATH="${${(%):-%x}:A}"

# Get the root directory of ghq repositories.
# Outputs:
#   Writes ghq root path to stdout.
function _ghq_fzf_get_root() {
  emulate -L zsh
  local root
  root="$(ghq root 2>/dev/null)" || true
  if [[ -n "${root}" ]]; then
    echo "${root}"
  else
    echo "${HOME}/dev/ghq"
  fi
}

# Retrieve list of repositories managed by ghq.
# Outputs:
#   Writes newline-separated repository list to stdout.
#   Writes error message to stderr if ghq is missing.
function _ghq_fzf_get_list() {
  emulate -L zsh
  local list
  if ! list="$(ghq list 2>/dev/null)"; then
    echo "Error: ghq is not installed." >&2
    return 1
  fi
  echo "${list}"
}

# Save selected repository to history file.
# Arguments:
#   repo_rel - Relative repository path (e.g. github.com/user/repo).
function _ghq_fzf_save_history() {
  emulate -L zsh
  local repo_rel="$1"
  [[ -z "${repo_rel}" ]] && return 0

  local history_file="${GHQ_FZF_HISTORY_FILE:-${XDG_CACHE_HOME:-$HOME/.cache}/ghq_fzf/history}"
  local dir="${history_file:h}"
  mkdir -p "${dir}"

  local tmp
  tmp="$(mktemp)"
  if [[ -f "${history_file}" ]]; then
    grep -v -F -x "${repo_rel}" "${history_file}" > "${tmp}" || true
  fi
  echo "${repo_rel}" >> "${tmp}"
  mv "${tmp}" "${history_file}"
}

# Get repository list ordered by Most Recently Used (MRU) first.
# Outputs:
#   Writes MRU-ordered repository list to stdout.
function _ghq_fzf_get_ordered_list() {
  emulate -L zsh
  local all_list
  all_list="$(_ghq_fzf_get_list)"
  if [[ -z "${all_list}" ]]; then
    return 0
  fi

  local history_file="${GHQ_FZF_HISTORY_FILE:-${XDG_CACHE_HOME:-$HOME/.cache}/ghq_fzf/history}"
  if [[ ! -f "${history_file}" ]]; then
    echo "${all_list}"
    return 0
  fi

  local hist_rev=""
  hist_rev="$(awk '{a[NR]=$0} END {for (i=NR; i>=1; i--) print a[i]}' "${history_file}" 2>/dev/null || true)"

  if [[ -z "${hist_rev}" ]]; then
    echo "${all_list}"
    return 0
  fi

  local valid_hist
  valid_hist="$(awk 'NR==FNR {a[$0]=1; next} ($0 in a)' <(echo "${all_list}") <(echo "${hist_rev}"))"

  local remaining
  if [[ -n "${valid_hist}" ]]; then
    remaining="$(awk 'NR==FNR {a[$0]=1; next} !($0 in a)' <(echo "${valid_hist}") <(echo "${all_list}"))"
  else
    remaining="${all_list}"
  fi

  if [[ -n "${valid_hist}" && -n "${remaining}" ]]; then
    printf "%s\n%s\n" "${valid_hist}" "${remaining}"
  elif [[ -n "${valid_hist}" ]]; then
    echo "${valid_hist}"
  else
    echo "${remaining}"
  fi
}

# Render preview window for fzf showing git status and file listing.
# Arguments:
#   repo_rel - Relative repository path.
# Outputs:
#   Writes git status summary and file listing to stdout.
#   Writes error message to stderr if directory is missing.
function _ghq_fzf_render_preview() {
  emulate -L zsh
  local repo_rel="$1"
  local ghq_root
  ghq_root="$(_ghq_fzf_get_root)"
  local full_path="${ghq_root}/${repo_rel}"

  if [[ ! -d "${full_path}" ]]; then
    echo "Directory not found: ${full_path}" >&2
    return 1
  fi

  local git_stat
  git_stat="$(git -C "${full_path}" status -s 2>/dev/null || true)"
  if [[ -n "${git_stat}" ]]; then
    echo "${git_stat}"
    echo ""
  fi

  local preview_cols="${FZF_PREVIEW_COLUMNS:-${COLUMNS:-80}}"
  local min_cols_for_table=75

  if (( $+commands[eza] )); then
    if (( preview_cols >= min_cols_for_table )); then
      eza --color=always -la --icons --time-style=long-iso "${full_path}"
    else
      eza --color=always -1a --icons "${full_path}"
    fi
  else
    ls -la "${full_path}"
  fi
}

# Open selected repository in Neovim or default system application.
# Arguments:
#   repo_rel - Relative repository path.
function _ghq_fzf_open_in_editor() {
  emulate -L zsh
  local repo_rel="$1"
  local ghq_root
  ghq_root="$(_ghq_fzf_get_root)"
  local full_path="${ghq_root}/${repo_rel}"

  _ghq_fzf_save_history "${repo_rel}"

  if (( $+commands[nvim] )); then
    nvim "${full_path}"
  else
    open "${full_path}"
  fi
}

# Interactive fuzzy finder for ghq repositories.
# Arguments:
#   --preview <path> - Render preview for path and exit.
#   --open <path> - Open path in editor and exit.
#   --editor - Directly open selected repository in editor.
#   [query] - Optional initial search query.
# Outputs:
#   Writes selected repository absolute path to stdout.
#   Writes error messages to stderr on missing dependencies or empty repository list.
function ghq_fzf() {
  emulate -L zsh
  local mode="select"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --preview)
        _ghq_fzf_render_preview "${2:-}"
        return 0
        ;;
      --open)
        _ghq_fzf_open_in_editor "${2:-}"
        return 0
        ;;
      --editor)
        mode="editor"
        shift
        ;;
      *)
        shift
        ;;
    esac
  done

  local self_bin="${${(%):-%x}:A}"
  if [[ -z "${self_bin}" || ! -f "${self_bin}" ]]; then
    self_bin="${_GHQ_FZF_SCRIPT_PATH:-${${funcsourcetrace[1]%:*}:A}}"
  fi
  if [[ -z "${self_bin}" || ! -f "${self_bin}" ]]; then
    self_bin="${0:A}"
  fi

  local list
  list="$(_ghq_fzf_get_ordered_list)"
  if [[ -z "${list}" ]]; then
    echo "No repositories found." >&2
    return 1
  fi

  if ! (( $+commands[fzf] )); then
    echo "Error: fzf is not installed." >&2
    return 1
  fi

  local selected_rel=""
  selected_rel="$(echo "${list}" | fzf \
    --prompt="Repo> " \
    --header="Enter: Select | Ctrl-O: Open in Neovim" \
    --preview="zsh \"${self_bin}\" --preview {}" \
    --preview-window="right:50%" \
    --bind="ctrl-o:execute(zsh \"${self_bin}\" --open {})+accept"
  )" || return 1

  if [[ -z "${selected_rel}" ]]; then
    return 1
  fi

  _ghq_fzf_save_history "${selected_rel}"

  local ghq_root
  ghq_root="$(_ghq_fzf_get_root)"
  local selected_full="${ghq_root}/${selected_rel}"

  if [[ "${mode}" == "editor" ]]; then
    _ghq_fzf_open_in_editor "${selected_rel}"
  else
    echo "${selected_full}"
  fi
}

if [[ "${ZSH_EVAL_CONTEXT}" == "toplevel" ]]; then
  ghq_fzf "$@"
fi

# Change directory to selected ghq repository.
function cghq() {
  emulate -L zsh
  local repo_dir
  repo_dir="$(ghq_fzf "$@")" || return
  if [[ -n "${repo_dir}" && -d "${repo_dir}" ]]; then
    cd "${repo_dir}" || return 1
  fi
}
