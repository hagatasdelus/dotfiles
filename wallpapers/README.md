# Wallpapers

## Daily rotation

`rotate.sh` selects one generated wallpaper per local date and writes it to `~/.local/state/ghostty/wallpaper.conf`. Ghostty includes that file with:

```text
config-file = ?~/.local/state/ghostty/wallpaper.conf
```

The selection is deterministic. The date is converted to a day number, and `day_number % wallpaper_count` chooses from the top-level generated images(sorted by name).
With a fixed set of images, the same date always selects the same image.
If the date has changed but the date-based candidate is already the current image (for example after adding or removing wallpapers), the next image is used so the background still changes.

At least two top-level images are required. `originals/` is not used directly;
generate wallpapers with `just blur`, `just gradient`, or `just both` first.

### Install the daily job

```sh
scripts/darwin/install-ghostty-wallpaper.sh
```

This registers `local.ghostty-wallpaper` as a LaunchAgent. It runs at local 00:00 and at login.
If the Mac is asleep at midnight, launchd runs the missed job on wake; if it is off, the login run applies the current date's image.
When Ghostty is running, the script sends `SIGUSR2` to reload the config immediately.
When it is not running, the new image is used on the next launch.

The setup is one-time and survives reboots. Run the install script again only if the dotfiles path changes. Logs are written to `~/Library/Logs/ghostty-wallpaper.log`.

### Manual use

```sh
./rotate.sh --dry-run
./rotate.sh
./rotate.sh --date 2026-10-24 --dry-run
./tests/rotate.test.sh
```

`--dry-run` prints the selected path without writing or reloading.
`--no-reload` updates the config without signaling Ghostty; setting `GHOSTTY_RELOAD=0` has the same effect.

To uninstall the LaunchAgent:

```sh
launchctl bootout "gui/$(id -u)/local.ghostty-wallpaper"
rm ~/Library/LaunchAgents/local.ghostty-wallpaper.plist
```
