# Fish shell entry point
#
# Configuration is modularized according to fish de-facto standards and SHELL_REPORT.md:
#   conf.d/00-env.fish          Environment variables
#   conf.d/10-path.fish         PATH configuration with fish_add_path
#   conf.d/20-interactive.fish  Interactive session setup, caching, hooks
#   conf.d/30-alias.fish        Command aliases
#   conf.d/40-keybindings.fish  Keybindings
#   functions/                  Autoloaded functions
#
# Local machine-specific overrides can be placed in config.local.fish

if test -f "$XDG_CONFIG_HOME/fish/config.local.fish"
    source "$XDG_CONFIG_HOME/fish/config.local.fish"
else if test -f "$HOME/.config/fish/config.local.fish"
    source "$HOME/.config/fish/config.local.fish"
end
