#!/bin/bash
set -euo pipefail

# Compute a perceptual hash of an image file
# Uses ImageMagick to create a simple perceptual hash based on scaled-down image

IMAGE_FILE="$1"

if [[ ! -f "$IMAGE_FILE" ]]; then
    echo "Error: File not found: $IMAGE_FILE" >&2
    exit 1
fi

# Generate a perceptual hash by:
# 1. Resize to 8x8 (64 pixels)
# 2. Convert to grayscale
# 3. Get raw pixel values and hash them
# This creates a simple perceptual hash that's resistant to minor changes

HASH=$(convert "$IMAGE_FILE" -resize 8x8! -colorspace Gray -depth 8 txt:- 2>/dev/null | \
    grep -oE 'graya?\([0-9]+' | \
    cut -d'(' -f2 | \
    tr '\n' ' ' | \
    md5sum | \
    cut -d' ' -f1)

echo "$HASH"
