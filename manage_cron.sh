#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FETCH_SCRIPT="$SCRIPT_DIR/fetch_wallpapers.sh"
CHANGE_SCRIPT="$SCRIPT_DIR/change_wallpaper.sh"

CRON_TAG="# WALLPAPER_MANAGER_CRON"

usage() {
    echo "Usage: $0 {install|uninstall|status}"
    echo
    echo "Commands:"
    echo "  install    - Configures cron jobs (Wallpaper every 5 mins, Fetch daily at 03:00)"
    echo "  uninstall  - Removes all wallpaper manager cron jobs"
    echo "  status     - Shows current installed cron jobs"
    exit 1
}

ensure_executable() {
    chmod +x "$FETCH_SCRIPT" "$CHANGE_SCRIPT"
}

install_cron() {
    ensure_executable
    uninstall_cron > /dev/null 2>&1 || true

    # Default intervals:
    # - change_wallpaper.sh: Every 5 minutes (*/5 * * * *)
    # - fetch_wallpapers.sh: Daily at 3:00 AM (0 3 * * *)
    NEW_ENTRIES=$(cat <<EOF
$CRON_TAG
*/5 * * * * "$CHANGE_SCRIPT" >/dev/null 2>&1 $CRON_TAG
0 3 * * * "$FETCH_SCRIPT" >/dev/null 2>&1 $CRON_TAG
EOF
)

    (crontab -l 2>/dev/null || true; echo "$NEW_ENTRIES") | crontab -
    echo "Cron jobs installed successfully."
    echo "Rotation: Every 5 minutes"
    echo "Refresh:  Daily at 03:00"
}

uninstall_cron() {
    local CURRENT_CRON
    CURRENT_CRON=$(crontab -l 2>/dev/null || true)

    if [[ -z "$CURRENT_CRON" ]]; then
        echo "No cron jobs found."
        return
    fi

    echo "$CURRENT_CRON" | grep -v "$CRON_TAG" | crontab -
    echo "Wallpaper manager cron jobs removed."
}

status_cron() {
    echo "--- Current Wallpaper Cron Jobs ---"
    crontab -l 2>/dev/null | grep "$CRON_TAG" || echo "No active jobs."
}

case "${1:-}" in
    install)   install_cron ;;
    uninstall) uninstall_cron ;;
    status)    status_cron ;;
    *)         usage ;;
esac