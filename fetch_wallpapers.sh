#!/bin/bash
set -euo pipefail

# Configuration
DEST_DIR="${HOME}/Pictures/Wallpapers/Wallhaven"
MAX_POOL_SIZE=100
PAGES_TO_FETCH=1
RESOLUTIONS="3840x2160"
RATIOS="16x9"
SORTING="random"

# Hash database files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HASH_DB_DIR="${HOME}/.local/share/wallpaper-hashes"
DOWNLOADED_HASHES="${HASH_DB_DIR}/downloaded.txt"
DELETED_HASHES="${HASH_DB_DIR}/deleted.txt"

# Initialize hash databases
mkdir -p "$HASH_DB_DIR"
touch "$DOWNLOADED_HASHES"
touch "$DELETED_HASHES"

# --- Curated Category & Tag Settings ---
CATEGORIES="100"      # 100 = General ONLY (Turns off Anime and People categories)
PURITY="100"          # 100 = SFW

# Wallhaven tag queries (picks a random thematic tag each fetch run)
QUERIES=(
    "nature"
    "landscape"
    "mountains"
    "forest"
    "aerial view"
    "bird"
    "animals"
    "ocean"
    "sea"
    "sunset"
    "sunrise"
    "cityscape"
    "architecture"
)

EXCLUDED_TROPES="-anime -illustration -vector -character"

# Pick a random query preset per fetch execution
QUERY="${QUERIES[$RANDOM % ${#QUERIES[@]}]} ${EXCLUDED_TROPES}"

API_KEY=""
mkdir -p "$DEST_DIR"

# 1. Fetch & Download New Images
DOWNLOADED_COUNT=0
DUPLICATE_COUNT=0

for (( page=1; page<=PAGES_TO_FETCH; page++ )); do
    API_URL="https://wallhaven.cc/api/v1/search?resolutions=${RESOLUTIONS}&ratios=${RATIOS}&sorting=${SORTING}&categories=${CATEGORIES}&purity=${PURITY}&page=${page}"
    [[ -n "$QUERY" ]] && API_URL="${API_URL}&q=$(echo "$QUERY" | tr ' ' '+')"
    [[ -n "$API_KEY" ]] && API_URL="${API_URL}&apikey=${API_KEY}"

    IMAGE_URLS=$(curl -s "$API_URL" | jq -r '.data[].path // empty' 2>/dev/null || true)

    if [[ -z "$IMAGE_URLS" ]]; then
        continue
    fi

    for URL in $IMAGE_URLS; do
        FILENAME=$(basename "$URL")
        TARGET_FILE="$DEST_DIR/$FILENAME"

        # Download if not already present
        if [[ ! -f "$TARGET_FILE" ]]; then
            curl -s -o "$TARGET_FILE" "$URL"

            # Check if ImageMagick is available
            if command -v convert &> /dev/null; then
                # Hash the downloaded image
                HASH=$("$SCRIPT_DIR/hash_image.sh" "$TARGET_FILE" 2>/dev/null || echo "")

                if [[ -n "$HASH" ]]; then
                    # Check if this hash exists in downloaded or deleted databases
                    if grep -qF "$HASH" "$DOWNLOADED_HASHES" 2>/dev/null || \
                       grep -qF "$HASH" "$DELETED_HASHES" 2>/dev/null; then
                        # Duplicate found - delete it
                        rm -f "$TARGET_FILE"
                        ((DUPLICATE_COUNT++))
                        echo "Skipped duplicate: $FILENAME"
                    else
                        # New image - record its hash
                        echo "$HASH" >> "$DOWNLOADED_HASHES"
                        ((DOWNLOADED_COUNT++))
                        echo "Downloaded: $FILENAME"
                    fi
                else
                    # Hashing failed, but keep the image
                    ((DOWNLOADED_COUNT++))
                fi
            else
                # ImageMagick not available, just keep the image
                ((DOWNLOADED_COUNT++))
            fi
        fi
    done
done

echo "Downloaded: $DOWNLOADED_COUNT new images, skipped $DUPLICATE_COUNT duplicates"

# 2. Pool Freshening / Cleanup: Remove oldest files exceeding MAX_POOL_SIZE
CURRENT_COUNT=$(find "$DEST_DIR" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" \) | wc -l)

if (( CURRENT_COUNT > MAX_POOL_SIZE )); then
    OVERFLOW=$(( CURRENT_COUNT - MAX_POOL_SIZE ))
    find "$DEST_DIR" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" \) -printf '%T+ %p\n' \
        | sort \
        | head -n "$OVERFLOW" \
        | cut -d' ' -f2- \
        | xargs -d '\n' rm -f
fi