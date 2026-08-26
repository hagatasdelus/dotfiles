# Environment variables for fish (set for all shells)

# XDG Base Directory Specification
set -q XDG_CONFIG_HOME; or set -gx XDG_CONFIG_HOME $HOME/.config
set -q XDG_CACHE_HOME; or set -gx XDG_CACHE_HOME $HOME/.cache
set -q XDG_DATA_HOME; or set -gx XDG_DATA_HOME $HOME/.local/share
set -q XDG_STATE_HOME; or set -gx XDG_STATE_HOME $HOME/.local/state

set -gx TERMINFO "/usr/share/terminfo/"
set -gx SQLITE_HISTORY "$XDG_STATE_HOME/sqlite_history"
set -gx PYTHON_HISTORY "$XDG_STATE_HOME/python_history"

# Locale & Language
set -gx LANGUAGE "en_US:en"
set -gx LANG "en_US.UTF-8"
set -gx LC_ALL "en_US.UTF-8"
set -gx PLATFORM (uname)

# Default Editor
if type -q nvim
    set -gx EDITOR nvim
    set -gx VISUAL nvim
    set -gx GIT_EDITOR nvim
else if type -q vim
    set -gx EDITOR vim
    set -gx VISUAL vim
    set -gx GIT_EDITOR vim
end

# Homebrew environment
set -gx HOMEBREW_NO_EMOJI 1
set -gx HOMEBREW_FORBIDDEN_FORMULAE "node python python3 pip npm pnpm yarn go"

# Java settings
set -gx _JAVA_OPTIONS "-Dfile.encoding=UTF-8"
if test -x /usr/libexec/java_home
    set -l java_path (/usr/libexec/java_home -v "23" 2>/dev/null; or /usr/libexec/java_home 2>/dev/null)
    if test -n "$java_path"
        set -gx JAVA_HOME $java_path
    end
end

# Apache Ant
if test -d /usr/local/ant
    set -gx ANT_HOME /usr/local/ant
    set -gx ANT_OPTS "-Dfile.encoding=UTF-8 -Xmx512m -Xss256k"
end

# Deno
set -gx DENO_INSTALL "$HOME/.deno"

# PNPM
if test -d "$HOME/.local/share/pnpm"
    set -gx PNPM_HOME "$HOME/.local/share/pnpm"
end

# Terminal colors
set -gx CLICOLOR 1
set -gx LSCOLORS "gxfxcxdxbxegedabagacad"

# GHQ Root
if type -q git
    set -l ghq_root (git config ghq.root 2>/dev/null)
    if test -n "$ghq_root"
        set -gx GHROOT "$ghq_root/github.com"
    end
end

# Notification duration threshold (milliseconds for fish CMD_DURATION)
set -gx NOTIFY_ON_COMMAND_DURATION 5000
