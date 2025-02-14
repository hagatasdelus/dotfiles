#!/bin/sh

check_git_hooks_dir() {
    if [ ! -d ~/.config/git/hooks ]; then
        echo "~/.config/git/hooks directory does not exist."
        exit 1
    fi
}

git config --local commit.template ~/.config/git/commit-template

if [ ! -d ".git" ]; then
    echo "Current directory is not a git repository."
    exit 1
fi

read -p "Do you use Git Hooks in this repository? (y/N): " ANS </dev/tty
case "${ANS}" in
[yY]*)
    check_git_hooks_dir

    for HOOK in ~/.config/git/hooks/*; do
        if [ -f ${HOOK} ]; then
            cp ${HOOK} .git/hooks/
            HOOK_NAME=$(basename ${HOOK})
            chmod +x .git/hooks/${HOOK_NAME}
            echo "Installed: ${HOOK_NAME}"
        fi
    done
    ;;
[nN]*)
    check_git_hooks_dir

    for HOOK in ~/.config/git/hooks/*; do
        if [ -f ${HOOK} ]; then
            HOOK_NAME=$(basename ${HOOK})
            if [ -f ".git/hooks/${HOOK_NAME}" ]; then
                rm ".git/hooks/${HOOK_NAME}"
                echo "Removed: ${HOOK_NAME}"
            fi
        fi
    done
    ;;
*)
    echo "Invalid input."
    ;;
esac

echo "Setup done."

exit 0
