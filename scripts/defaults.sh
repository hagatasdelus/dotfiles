#!/usr/bin/env bash

set -euo pipefail

if [[ "$(uname)" != "Darwin" ]]; then
    echo "Not macOS, skipping defaults settings."
    exit 0
fi

defaults write -g KeyRepeat -int 1
defaults write -g InitialKeyRepeat -int 10

echo "Done. you may need to log out and log in again."
