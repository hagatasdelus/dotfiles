# Aliases for fish

# Core replacement aliases
alias ls='eza'
alias eza='eza -l --header --icons'
alias la='ls -la'
alias ll='ls -l'

# Custom shell scripts & tools
alias b2a='sh $HOME/bin/b2a.sh'
alias auth='sh $HOME/bin/auth.sh'
alias karabiner_cli="/Library/Application\ Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli"
alias arto='/Applications/Arto.app/Contents/MacOS/arto'
alias notify='sh $HOME/.scripts/notification.sh'
alias java_home-v='sh $HOME/.scripts/java_home-v.sh'
alias edit='open -a "Visual Studio Code"'

# Utilities
alias nl='nl -ba -s ": "'
alias tree='go run $HOME/scripts/tree.go'
alias h='history'
alias h2='history 20'
alias cl='printf "\33c\e[3J"'
alias path='echo $PATH | tr " " "\n"'

# Fuzzy finder integration aliases
alias fv='rg --files --hidden --glob "!.git" | fzf --preview "bat --style=numbers --color=always --line-range :500 {}" --bind "enter:become(nvim {})"'
alias fg='fzf --bind "change:reload:rg --line-number --no-heading --color=always --smart-case {q} || true" --ansi --delimiter : --preview "bat --style=numbers --color=always --highlight-line {2} {1}" --preview-window "up,60%,border-bottom,+{2}+3/3,~3" --bind "enter:become(nvim +{2} {1})"'
