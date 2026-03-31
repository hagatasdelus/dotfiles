alias ls='eza'
alias eza='eza -l --header --icons'
alias b2a='sh ${HOME}/bin/b2a.sh'
alias auth='sh ${HOME}/bin/auth.sh'
alias karabiner_cli="/Library/Application\ Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli"
alias fv='rg --files --hidden --glob "!.git" | fzf --preview "bat --style=numbers --color=always --line-range :500 {}" --bind "enter:become(nvim {})"'
alias fg='fzf --bind "change:reload:rg --line-number --no-heading --color=always --smart-case {q} || true" --ansi --delimiter : --preview "bat --style=numbers --color=always --highlight-line {2} {1}" --preview-window "up,60%,border-bottom,+{2}+3/3,~3" --bind "enter:become(nvim +{2} {1})"'

alias arto='/Applications/Arto.app/Contents/MacOS/arto'
