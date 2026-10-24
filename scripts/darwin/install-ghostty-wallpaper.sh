#!/usr/bin/env bash
# Install the daily Ghostty wallpaper rotation LaunchAgent.
#
#   scripts/darwin/install-ghostty-wallpaper.sh
#
# The agent runs at local 00:00 and at login. It is a one-time setup; it survives reboots.
# Run this again only if the dotfiles path changes.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../.."
DOTFILES_DIR=$(pwd -P)
LABEL=local.ghostty-wallpaper
AGENT_PATH="$HOME/Library/LaunchAgents/$LABEL.plist"
TEMPLATE="$DOTFILES_DIR/common/Library/LaunchAgents/$LABEL.plist.template"
ROTATE="$DOTFILES_DIR/wallpapers/rotate.sh"

if [[ ! -f $TEMPLATE ]]; then
  echo "error: LaunchAgent template not found: $TEMPLATE" >&2
  exit 1
fi
if [[ ! -f $ROTATE ]]; then
  echo "error: rotation script not found: $ROTATE" >&2
  exit 1
fi
chmod +x "$ROTATE"

"$ROTATE"

mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
sed -e "s|__DOTFILES__|$DOTFILES_DIR|g" -e "s|__HOME__|$HOME|g" \
  "$TEMPLATE" >"$AGENT_PATH"
plutil -lint "$AGENT_PATH" >/dev/null

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
if ! launchctl bootstrap "gui/$(id -u)" "$AGENT_PATH"; then
  echo "error: failed to register $AGENT_PATH" >&2
  exit 1
fi

echo "ghostty-wallpaper LaunchAgent registered."
echo "log: $HOME/Library/Logs/ghostty-wallpaper.log"
