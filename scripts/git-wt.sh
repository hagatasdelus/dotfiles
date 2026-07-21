git config --global wt.nocd create
git config --add --global wt.hook 'command -v herdr >/dev/null && [ -n "$HERDR_ENV" ] && herdr worktree open --path "$PWD" --no-focus; true'
