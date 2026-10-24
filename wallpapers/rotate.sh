#!/usr/bin/env bash
# Rotate the Ghostty background image once per local date.
#
# The selected image is written to a Ghostty config include and the running
# Ghostty process is asked to reload it with SIGUSR2. This script is intentionally independent of Herdr.
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
WALLPAPERS_DIR=${WALLPAPERS_DIR:-$SCRIPT_DIR}
STATE_DIR=${STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/ghostty}
if [[ -d $STATE_DIR ]]; then
  STATE_DIR=$(cd "$STATE_DIR" && pwd -P)
fi
STATE_FILE=$STATE_DIR/wallpaper.conf
TARGET_DATE=$(date +%Y-%m-%d)
DRY_RUN=false
RELOAD=true

function usage() {
  cat <<'EOF'
Usage: rotate.sh [options]

Select one generated wallpaper for a local date, write it to the Ghostty
include file, and reload Ghostty if it is running.

Options:
  --date YYYY-MM-DD  Select for this date (default: today)
  --dry-run          Print the selected path without writing or reloading
  --no-reload        Update the config without sending SIGUSR2
  -h, --help         Show this help

Environment:
  WALLPAPERS_DIR     Directory containing generated wallpapers
                     (default: the directory containing this script)
  STATE_DIR          Directory for wallpaper.conf
                     (default: $XDG_STATE_HOME/ghostty or ~/.local/state/ghostty)
  GHOSTTY_RELOAD=0   Same as --no-reload

At least two top-level images are required. The originals/ directory is not
used directly; generate wallpapers with `just both originals/<name>` first.
EOF
}

# Return the number of days since the Unix epoch for a YYYY-MM-DD calendar date. Parsing the date as UTC avoids daylight-saving transitions.
function day_ordinal() {
  local value=$1
  local epoch canonical
  if epoch=$(date -u -j -f "%Y-%m-%d" "$value" +%s 2>/dev/null); then
    canonical=$(date -u -j -f "%Y-%m-%d" "$value" +%Y-%m-%d 2>/dev/null)
  else
    epoch=$(date -u -d "$value" +%s 2>/dev/null) || return 1
    canonical=$(date -u -d "@$epoch" +%Y-%m-%d 2>/dev/null) || return 1
  fi
  [[ $canonical == "$value" ]] || return 1
  printf '%s\n' $((epoch / 86400))
}

function list_wallpapers() {
  find "$WALLPAPERS_DIR" -maxdepth 1 -type f \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) \
    -print | LC_ALL=C sort
}

function reload_ghostty() {
  local pids pid
  pids=$(ps -axo pid=,ucomm= | awk '$2 == "ghostty" { print $1 }')
  if [[ -z $pids ]]; then
    echo "Ghostty is not running; the new wallpaper will apply on next launch." >&2
    return 0
  fi
  while IFS= read -r pid; do
    [[ -n $pid ]] || continue
    if kill -USR2 "$pid" 2>/dev/null; then
      echo "Reloaded Ghostty (pid $pid)." >&2
    else
      echo "warning: failed to signal Ghostty (pid $pid)." >&2
    fi
  done <<<"$pids"
}

while (($# > 0)); do
  case "$1" in
    --date)
      if (($# < 2)); then
        echo "error: --date requires YYYY-MM-DD" >&2
        exit 2
      fi
      TARGET_DATE=$2
      shift 2
      ;;
    --date=*)
      TARGET_DATE=${1#*=}
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --no-reload)
      RELOAD=false
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ ! $TARGET_DATE =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || ! day_ordinal "$TARGET_DATE" >/dev/null; then
  echo "error: invalid date: $TARGET_DATE (expected YYYY-MM-DD)" >&2
  exit 2
fi

if [[ ! -d $WALLPAPERS_DIR ]]; then
  echo "error: wallpaper directory not found: $WALLPAPERS_DIR" >&2
  exit 1
fi
WALLPAPERS_DIR=$(cd "$WALLPAPERS_DIR" && pwd -P)

wallpapers=()
while IFS= read -r image; do
  wallpapers+=("$image")
done < <(list_wallpapers)
count=${#wallpapers[@]}
if ((count < 2)); then
  echo "error: at least 2 generated wallpapers are required in $WALLPAPERS_DIR (found $count)" >&2
  echo "hint: run 'just both originals/<name>' for each original you want to use" >&2
  exit 1
fi

current_date=""
current_image=""
if [[ -f $STATE_FILE ]]; then
  current_date=$(awk '/^# date: / { sub(/^# date: /, ""); print; exit }' "$STATE_FILE")
  current_image=$(awk '/^background-image = / { sub(/^background-image = /, ""); print; exit }' "$STATE_FILE")
fi

if [[ $current_date == "$TARGET_DATE" && -n $current_image && -f $current_image ]]; then
  printf '%s\n' "$current_image"
  exit 0
fi

ordinal=$(day_ordinal "$TARGET_DATE")
index=$((ordinal % count))
candidate=${wallpapers[$index]}

# If the image list changed, the date-based candidate can already be the current image. Advance once so the date change still changes the wallpaper.
if [[ -n $current_image && $candidate == "$current_image" ]]; then
  index=$(((index + 1) % count))
  candidate=${wallpapers[$index]}
fi

if [[ $DRY_RUN == true ]]; then
  printf '%s\n' "$candidate"
  exit 0
fi

mkdir -p "$STATE_DIR"
STATE_DIR=$(cd "$STATE_DIR" && pwd -P)
STATE_FILE=$STATE_DIR/wallpaper.conf

tmp=$(mktemp "$STATE_FILE.XXXXXX")
trap 'rm -f "$tmp"' EXIT
{
  printf '# Generated by %s. Do not edit.\n' "${BASH_SOURCE[0]}"
  printf '# date: %s\n' "$TARGET_DATE"
  printf 'background-image = %s\n' "$candidate"
} >"$tmp"
mv "$tmp" "$STATE_FILE"
trap - EXIT

printf '%s\n' "$candidate"

if [[ $RELOAD == true && ${GHOSTTY_RELOAD:-1} != 0 ]]; then
  reload_ghostty
fi
