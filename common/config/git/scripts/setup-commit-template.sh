#!/bin/sh

git config --global commit.template ~/.config/git/commit_template

if [ -d ".git" ]; then
    cp ~/.config/git/hooks/prepare-commit-msg .git/hooks/
    chmod +x .git/hooks/prepare-commit-msg
    echo "Git hooks have been set up for this repository."
else
    echo "Current directory is not a git repository."
fi

exit 0
