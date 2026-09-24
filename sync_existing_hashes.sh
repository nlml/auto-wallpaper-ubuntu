#!/bin/bash
set -euo pipefail

# Sync existing wallpapers into the hash database
# Run this once to populate the database with currently downloaded wallpapers

DEST_DIR="${HOME}/Pictures/Wallpapers/Wallhaven"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HASH_DB_DIR="${HOME}/.local/share/wallpaper-hashes"
DOWNLOADED_HASHES="${HASH_DB_DIR}/downloaded.txt"

# Initialize hash database
mkdir -p "$HASH_DB_DIR"
touch "$DOWNLOADED_HASHES"

if ! command -v convert &> /dev/null; then
    echo "Error: ImageMagick (convert command) is required but not installed." >&2
    echo "Install with: sudo apt install imagemagick" >&2
    exit 1
fi

echo "Scanning existing wallpapers in $DEST_DIR..."

COUNT=0
SKIPPED=0

# Find all image files
while IFS= read -r -d '' IMAGE; do
    # Check if already in database
    TEMP_HASH=$("$SCRIPT_DIR/hash_image.sh" "$IMAGE" 2>/dev/null || echo "")

    if [[ -n "$TEMP_HASH" ]]; then
        if grep -qF "$TEMP_HASH" "$DOWNLOADED_HASHES" 2>/dev/null; then
            SKIPPED=$((SKIPPED + 1))
        else
            echo "$TEMP_HASH" >> "$DOWNLOADED_HASHES"
            COUNT=$((COUNT + 1))
            echo "Hashed: $(basename "$IMAGE")"
        fi
    fi
done < <(find "$DEST_DIR" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" \) -print0)

echo ""
echo "Complete! Added $COUNT new hashes, skipped $SKIPPED already-tracked images."
