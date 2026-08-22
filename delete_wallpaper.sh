#!/bin/bash
set -euo pipefail

DEST_DIR="${HOME}/Pictures/Wallpapers/Wallhaven"

# Cron/hotkey may run without the user desktop session environment.
# Export DBUS_SESSION_BUS_ADDRESS so gsettings communicates with the GNOME daemon.
PID=$(pgrep -u "$USER" gnome-session | head -n 1 || true)
if [[ -n "$PID" ]]; then
    DBUS_ADDR=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/"$PID"/environ 2>/dev/null | tr -d '\0' | cut -d= -f2- || true)
    if [[ -n "$DBUS_ADDR" ]]; then
        export DBUS_SESSION_BUS_ADDRESS="$DBUS_ADDR"
    fi
fi

# Fallback DBUS check for systemd-based user sessions
if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
fi

# Get the currently visible wallpaper URI (strip surrounding quotes and file:// prefix)
CURRENT_URI=$(gsettings get org.gnome.desktop.background picture-uri | tr -d "'")
CURRENT_PIC="${CURRENT_URI#file://}"

if [[ -z "$CURRENT_PIC" || ! -f "$CURRENT_PIC" ]]; then
    echo "No current wallpaper file found to delete." >&2
    exit 0
fi

# Only delete files that live in our wallpaper pool, to avoid nuking anything else.
case "$CURRENT_PIC" in
    "$DEST_DIR"/*)
        rm -f "$CURRENT_PIC"
        echo "Deleted: $CURRENT_PIC"
        ;;
    *)
        echo "Current wallpaper is not in $DEST_DIR; refusing to delete: $CURRENT_PIC" >&2
        exit 0
        ;;
esac

# Immediately switch to a new random wallpaper so we don't keep showing the deleted one.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/change_wallpaper.sh"
