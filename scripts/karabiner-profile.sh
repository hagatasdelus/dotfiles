#!/usr/bin/env bash
set -euo pipefail

KARABINER_CLI="/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli"
MACSKK_SCRIPT="$HOME/dev/ghq/github.com/hagatasdelus/dotfiles/scripts/macskk-keybinding.sh"

if [ ! -f "$KARABINER_CLI" ]; then
    echo "Error: karabiner_cli not found at $KARABINER_CLI" >&2
    exit 1
fi

notify() {
    local msg="$1"
    osascript -e "display notification \"$msg\" with title \"Karabiner Profile\""
}

CURRENT_PROFILE=$("$KARABINER_CLI" --show-current-profile-name | tr -d '\n' | xargs)

ALL_PROFILES=$("$KARABINER_CLI" --list-profile-names)

SWITCHABLE_PROFILES=""
while read -r name; do
    name=$(echo "$name" | xargs)
    if [ -n "$name" ] && [ "$name" != "$CURRENT_PROFILE" ]; then
        if [ -z "$SWITCHABLE_PROFILES" ]; then
            SWITCHABLE_PROFILES="$name"
        else
            SWITCHABLE_PROFILES="$SWITCHABLE_PROFILES"$'\n'"$name"
        fi
    fi
done <<< "$ALL_PROFILES"

if [ -z "$SWITCHABLE_PROFILES" ]; then
    notify "No other profiles available."
    exit 0
fi

CHOICE=$(echo "$SWITCHABLE_PROFILES" | fzf --prompt="Karabiner Profile > " --height=10 --layout=reverse --header="Select profile to switch (Current: $CURRENT_PROFILE):")

if [ -z "$CHOICE" ]; then
    echo "Cancelled."
    exit 0
fi

echo "Switching Karabiner profile from '$CURRENT_PROFILE' to '$CHOICE'..."
if "$KARABINER_CLI" --select-profile "$CHOICE"; then
    MACSKK_PROFILE=""
    if [ "$CHOICE" = "US" ]; then
        MACSKK_PROFILE="AZIK_US"
    elif [ "$CHOICE" = "JIS" ]; then
        MACSKK_PROFILE="AZIK_JIS"
    fi

    if [ -n "$MACSKK_PROFILE" ] && [ -f "$MACSKK_SCRIPT" ]; then
        echo "Switching macSKK keybinding to '$MACSKK_PROFILE'..."
        if "$MACSKK_SCRIPT" "$MACSKK_PROFILE"; then
            notify "Switched to $CHOICE ($MACSKK_PROFILE)"
        else
            notify "Switched to $CHOICE, but failed to sync macSKK"
        fi
    else
        notify "Switched to $CHOICE"
    fi
else
    notify "Failed to switch profile: $CHOICE"
fi
