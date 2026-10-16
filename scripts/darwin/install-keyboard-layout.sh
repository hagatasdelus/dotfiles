#!/usr/bin/env bash
# Install keyboard-layout (Karabiner / macSKK / Neovim keyboard layout switching)
#
#   scripts/darwin/install-keyboard-layout.sh [--skip-agent]
#
#   --skip-agent  Only link and build; do not register the LaunchAgent
#
#   1. symlink ~/.config/keyboard-layout
#   2. build the keyboard-layout CLI (bun build --compile)
#   3. build the keyboard-watcher (swiftc)
#   4. generate and register the LaunchAgent (its first sync runs immediately)
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../.."
DOTFILES_DIR="$(pwd)"
COMMON_DIR="${DOTFILES_DIR}/common"
TARGET_DIR="${DOTFILES_DIR}/scripts/darwin"

SKIP_AGENT='false'
for argument in "$@"; do
  case "${argument}" in
    --skip-agent) SKIP_AGENT='true' ;;
    *) echo "unknown option: ${argument}" >&2; exit 2 ;;
  esac
done

# symlink the config (runtime files stay under ~/.local/state)
echo "linking ~/.config/keyboard-layout"
ln -snf "${COMMON_DIR}/config/keyboard-layout" "${HOME}/.config/keyboard-layout"

# Build
if command -v bun >/dev/null 2>&1; then
  echo "building keyboard-layout (bun build --compile)"
  (cd "${DOTFILES_DIR}" && bun build --compile \
    --outfile scripts/darwin/bin/keyboard-layout \
    scripts/darwin/keyboard-layout.ts)
else
  echo "warning: bun is not installed, cannot build keyboard-layout" >&2
fi

if command -v swiftc >/dev/null 2>&1; then
  echo "building keyboard-watcher (swiftc)"
  swiftc -O "${TARGET_DIR}/KeyboardWatcher.swift" -o "${TARGET_DIR}/bin/keyboard-watcher"
else
  echo "warning: swiftc is not installed, cannot build keyboard-watcher" >&2
fi

# LaunchAgent
if [ "${SKIP_AGENT}" = 'true' ]; then
  echo "skipped: LaunchAgent registration (--skip-agent)"
  exit 0
fi

if [ ! -x "${TARGET_DIR}/bin/keyboard-watcher" ]; then
  echo "warning: keyboard-watcher is missing, not registering the LaunchAgent" >&2
  exit 0
fi

KEYBOARD_AGENT="${HOME}/Library/LaunchAgents/local.keyboard-layout.plist"
mkdir -p "${HOME}/Library/LaunchAgents" "${HOME}/Library/Logs"
sed -e "s|__DOTFILES__|${DOTFILES_DIR}|g" -e "s|__HOME__|${HOME}|g" \
  "${COMMON_DIR}/Library/LaunchAgents/local.keyboard-layout.plist.template" \
  >"${KEYBOARD_AGENT}"

launchctl bootout "gui/$(id -u)/local.keyboard-layout" 2>/dev/null || true
if launchctl bootstrap "gui/$(id -u)" "${KEYBOARD_AGENT}" 2>/dev/null; then
  echo "keyboard-layout LaunchAgent registered (first sync runs now)"
else
  echo "warning: failed to register the LaunchAgent (${KEYBOARD_AGENT})" >&2
  exit 1
fi

echo "keyboard-layout installed."
