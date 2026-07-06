#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $(basename "$0") <KeyBindingSetId>" >&2
    exit 1
fi

TARGET_ID="$1"

PLIST_PATH="$HOME/Library/Containers/net.mtgto.inputmethod.macSKK/Data/Library/Preferences/net.mtgto.inputmethod.macSKK.plist"
DOMAIN_PATH="${PLIST_PATH%.plist}"
PLISTBUDDY="/usr/libexec/PlistBuddy"

if [ ! -f "$PLIST_PATH" ]; then
    echo "Error: plist file not found at $PLIST_PATH" >&2
    exit 1
fi

CURRENT_ID=$(defaults read "$DOMAIN_PATH" selectedKeyBindingSetId 2>/dev/null || echo "")

if [ "$CURRENT_ID" == "$TARGET_ID" ]; then
    echo "macSKK is already using KeyBindingSet: $TARGET_ID"
    echo "No changes were made."
    exit 0
fi

VALID_ID=false
i=0
while :; do
    id=$("$PLISTBUDDY" -c "Print :keyBindingSets:$i:id" "$PLIST_PATH" 2>/dev/null || true)
    if [ -z "$id" ]; then
        break
    fi
    if [ "$id" == "$TARGET_ID" ]; then
        VALID_ID=true
        break
    fi
    ((++i))
done

if [ "$VALID_ID" = false ]; then
    echo "Error: KeyBindingSetId '$TARGET_ID' not found in macSKK settings." >&2
    exit 1
fi

defaults write "$DOMAIN_PATH" selectedKeyBindingSetId -string "$TARGET_ID"
# echo "macSKK KeyBindingSet changed: ${CURRENT_ID:-None} -> $TARGET_ID"

if pgrep -x "macSKK" > /dev/null; then
    killall macSKK
else
    echo "macSKK process is not running. Settings will be applied on next launch."
fi
