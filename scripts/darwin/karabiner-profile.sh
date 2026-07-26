#!/usr/bin/env bash
set -euo pipefail

readonly KARABINER_CLI='/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli'
readonly MACSKK_SCRIPT="${HOME}/dev/ghq/github.com/hagatasdelus/dotfiles/scripts/darwin/macskk-keybinding.sh"

function notify() {
  local message="$1"
  osascript -e "display notification \"${message}\" with title \"Karabiner Profile\""
}

function trim() {
  local text="$1"
  text="${text#"${text%%[![:space:]]*}"}"
  text="${text%"${text##*[![:space:]]}"}"
  echo "${text}"
}

function macskk_profile_for() {
  case "$1" in
    US) echo 'AZIK_US' ;;
    JIS) echo 'AZIK_JIS' ;;
    *) echo '' ;;
  esac
}

function sync_macskk() {
  local choice="$1"
  local macskk_profile="$2"

  if [[ -z "${macskk_profile}" || ! -f "${MACSKK_SCRIPT}" ]]; then
    notify "Switched to ${choice}"
    return
  fi

  echo "Switching macSKK keybinding to '${macskk_profile}'..."
  if "${MACSKK_SCRIPT}" "${macskk_profile}"; then
    notify "Switched to ${choice} (${macskk_profile})"
  else
    notify "Switched to ${choice}, but failed to sync macSKK"
  fi
}

function main() {
  if [[ ! -f "${KARABINER_CLI}" ]]; then
    echo "Error: karabiner_cli not found at ${KARABINER_CLI}" >&2
    return 1
  fi

  local current_profile
  current_profile="$(trim "$("${KARABINER_CLI}" --show-current-profile-name)")"

  local all_profiles
  all_profiles="$("${KARABINER_CLI}" --list-profile-names)"

  local switchable=()
  local name
  while read -r name; do
    name="$(trim "${name}")"
    if [[ -n "${name}" && "${name}" != "${current_profile}" ]]; then
      switchable+=("${name}")
    fi
  done <<< "${all_profiles}"

  if (( ${#switchable[@]} == 0 )); then
    notify "No other profiles available."
    return 0
  fi

  local choice
  choice="$(printf '%s\n' "${switchable[@]}" \
    | fzf --prompt="Karabiner Profile > " \
        --height=10 \
        --layout=reverse \
        --header="Select profile to switch (Current: ${current_profile}):")"

  if [[ -z "${choice}" ]]; then
    echo "Cancelled."
    return 0
  fi

  echo "Switching Karabiner profile from '${current_profile}' to '${choice}'..."
  if ! "${KARABINER_CLI}" --select-profile "${choice}"; then
    notify "Failed to switch profile: ${choice}"
    return 1
  fi

  local macskk_profile
  macskk_profile="$(macskk_profile_for "${choice}")"
  sync_macskk "${choice}" "${macskk_profile}"
}

main "$@"
