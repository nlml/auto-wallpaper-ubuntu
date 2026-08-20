#!/bin/bash
set -euo pipefail

DEST_DIR="${HOME}/Pictures/Wallpapers/Wallhaven"

# Cron runs without the user desktop session environment.
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

# Select a random wallpaper
PIC=$(find "$DEST_DIR" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" \) 2>/dev/null | shuf -n 1 || true)

if [[ -n "$PIC" ]]; then
    # Set for both Light and Dark GNOME themes
    gsettings set org.gnome.desktop.background picture-uri "file://$PIC"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$PIC"
fi