#
# PATH, fpath, and manpath search path configurations for zsh.
#

typeset -U path
typeset -U fpath
typeset -U manpath

# (N-/): N=NULL_GLOB, -=follow symlinks, /=directories only
typeset -a extra_path=(
  "${HOME}/scripts"(N-/)
  "${HOME}/.local/bin"(N-/)
  "${HOME}/.scripts"(N-/)
  "${HOME}/.scripts/bin"(N-/)
  "${HOME}/go/bin"(N-/)
  "${HOME}/.cargo/bin"(N-/)
  "${HOME}/.poetry/bin"(N-/)
  "${HOME}/.bun/bin"(N-/)
  "${HOME}/.deno/bin"(N-/)
  "${HOME}/.local/share/mise/shims"(N-/)
  "/Applications/Xcode.app/Contents/Developer/usr/bin"(N-/)
  "/opt/homebrew/bin"(N-/)
  "/opt/homebrew/sbin"(N-/)
  "/usr/local/bin"(N-/)
  "/usr/local/sbin"(N-/)
  "/opt/local/sbin"(N-/)
  "/usr/bin"(N-/)
  "/bin"(N-/)
  "/usr/sbin"(N-/)
  "/sbin"(N-/)
  "${HOME}/bin"(N-/)
)

if [[ -d "/opt/subversion/bin" ]]; then
  extra_path=("${extra_path[@]}" "/opt/subversion/bin"(N-/))
fi

if [[ -d "/usr/local/ant/bin" ]]; then
  extra_path=("${extra_path[@]}" "/usr/local/ant/bin"(N-/))
fi

if [[ -d "/usr/local/checker/bin" ]]; then
  extra_path=("${extra_path[@]}" "/usr/local/checker/bin"(N-/))
fi

path=(
  "${extra_path[@]}"
  "${path[@]}"
)

typeset -xT SUDO_PATH sudo_path
typeset -U sudo_path
sudo_path=(
  "${sudo_path[@]}"
  "/opt/homebrew/sbin"(N-/)
  "/usr/local/sbin"(N-/)
  "/usr/sbin"(N-/)
  "/sbin"(N-/)
)

fpath=(
  "${ZDOTDIR:-${HOME}/.config/zsh}/zfunc"(N-/)
  "${HOME}/.zfunc"(N-/)
  "/opt/homebrew/share/zsh/site-functions"(N-/)
  "/opt/homebrew/share/zsh/functions"(N-/)
  "/usr/local/share/zsh/site-functions"(N-/)
  "/usr/local/share/zsh/functions"(N-/)
  "${fpath[@]}"
)

manpath=(
  "${HOME}/.local/share/man"(N-/)
  "/opt/homebrew/share/man"(N-/)
  "/usr/local/share/man"(N-/)
  "/usr/share/man"(N-/)
  "${manpath[@]}"
)
