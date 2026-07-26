#!/usr/bin/env bash
set -euo pipefail

readonly PLIST_PATH="${HOME}/Library/Containers/net.mtgto.inputmethod.macSKK/Data/Library/Preferences/net.mtgto.inputmethod.macSKK.plist"
readonly DOMAIN_PATH="${PLIST_PATH%.plist}"
readonly PLIST_BUDDY='/usr/libexec/PlistBuddy'

function key_binding_set_exists() {
  local target_id="$1"

  local index=0
  local id
  while :; do
    id="$("${PLIST_BUDDY}" -c "Print :keyBindingSets:${index}:id" "${PLIST_PATH}" 2>/dev/null || true)"
    if [[ -z "${id}" ]]; then
      return 1
    fi
    if [[ "${id}" == "${target_id}" ]]; then
      return 0
    fi
    (( index += 1 ))
  done
}

function restart_macskk() {
  if pgrep -x 'macSKK' > /dev/null; then
    killall macSKK
  else
    echo "macSKK process is not running. Settings will be applied on next launch."
  fi
}

function main() {
  if (( $# < 1 )); then
    echo "Usage: $(basename "$0") <KeyBindingSetId>" >&2
    return 1
  fi
  local target_id="$1"

  if [[ ! -f "${PLIST_PATH}" ]]; then
    echo "Error: plist file not found at ${PLIST_PATH}" >&2
    return 1
  fi

  local current_id
  current_id="$(defaults read "${DOMAIN_PATH}" selectedKeyBindingSetId 2>/dev/null || echo '')"
  if [[ "${current_id}" == "${target_id}" ]]; then
    echo "macSKK is already using KeyBindingSet: ${target_id}"
    echo "No changes were made."
    return 0
  fi

  if ! key_binding_set_exists "${target_id}"; then
    echo "Error: KeyBindingSetId '${target_id}' not found in macSKK settings." >&2
    return 1
  fi

  defaults write "${DOMAIN_PATH}" selectedKeyBindingSetId -string "${target_id}"
  restart_macskk
}

main "$@"
