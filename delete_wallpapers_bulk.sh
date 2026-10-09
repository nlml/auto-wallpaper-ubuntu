#!/bin/bash
set -euo pipefail

DEST_DIR="${HOME}/Pictures/Wallpapers/Wallhaven"

# Hash database files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HASH_DB_DIR="${HOME}/.local/share/wallpaper-hashes"
DELETED_HASHES="${HASH_DB_DIR}/deleted.txt"

# Initialize hash database
mkdir -p "$HASH_DB_DIR"
touch "$DELETED_HASHES"

INTERACTIVE=0

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <image_path> [<image_path> ...]"
    echo "       $0 -i (interactive mode - paste paths and hit Ctrl+D)"
    exit 1
fi

# Strip a file:// URI prefix and percent-decode (file managers copy paths this way)
normalize_path() {
    local path="$1"
    path="${path#file://}"
    printf '%b' "${path//%/\\x}"
}

if [[ "$1" == "-i" ]]; then
    INTERACTIVE=1
    PATHS=()
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            PATHS+=("$(normalize_path "$line")")
        fi
    done
else
    PATHS=()
    for ARG in "$@"; do
        PATHS+=("$(normalize_path "$ARG")")
    done
fi

DELETED_COUNT=0
FAILED_COUNT=0

for IMAGE_PATH in "${PATHS[@]}"; do
    if [[ ! -f "$IMAGE_PATH" ]]; then
        echo "File not found: $IMAGE_PATH" >&2
        FAILED_COUNT=$((FAILED_COUNT + 1))
        continue
    fi

    # Hash the image before deleting it
    if command -v convert &> /dev/null && [[ -x "$SCRIPT_DIR/hash_image.sh" ]]; then
        HASH=$("$SCRIPT_DIR/hash_image.sh" "$IMAGE_PATH" 2>/dev/null || echo "")
        if [[ -n "$HASH" ]]; then
            # Record the hash so we never download this image again
            if ! grep -qF "$HASH" "$DELETED_HASHES" 2>/dev/null; then
                echo "$HASH" >> "$DELETED_HASHES"
            fi
        fi
    fi

    rm -f "$IMAGE_PATH"
    echo "Deleted: $IMAGE_PATH"
    DELETED_COUNT=$((DELETED_COUNT + 1))
done

echo "Deleted: $DELETED_COUNT images, failed: $FAILED_COUNT"
