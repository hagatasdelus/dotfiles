#!/usr/bin/env bash
set -euo pipefail

KARABINER_CLI="/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli"
MACSKK_SCRIPT="$HOME/dotfiles/common/config/wezterm/scripts/macskk-keybinding.sh"

if [ ! -f "$KARABINER_CLI" ]; then
    echo "Error: karabiner_cli not found at $KARABINER_CLI" >&2
    exit 1
fi

# Get current profile name
CURRENT_PROFILE=$("$KARABINER_CLI" --show-current-profile-name | tr -d '\n' | xargs)

if [ "$CURRENT_PROFILE" = "US" ]; then
    TARGET_PROFILE="JIS"
    MACSKK_PROFILE="AZIK_JIS"
else
    TARGET_PROFILE="US"
    MACSKK_PROFILE="AZIK_US"
fi

echo "Switching Karabiner profile from '$CURRENT_PROFILE' to '$TARGET_PROFILE'..."
"$KARABINER_CLI" --select-profile "$TARGET_PROFILE"

if [ -f "$MACSKK_SCRIPT" ]; then
    echo "Switching macSKK keybinding to '$MACSKK_PROFILE'..."
    "$MACSKK_SCRIPT" "$MACSKK_PROFILE"
else
    echo "Warning: macSKK keybinding script not found at $MACSKK_SCRIPT" >&2
fi
