#!/usr/bin/env bash
set -euo pipefail

# Download the Armbian S905W release asset and save it to the specified directory.
# Usage: ./scripts/get_armbian_s905w.sh [output-dir]

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$PROJECT_ROOT/data/config/flashing.config"

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    # shellcheck source=../data/config/flashing.config
    source "$CONFIG_FILE"
else
    echo "Error: Config file not found at $CONFIG_FILE" >&2
    exit 1
fi

OUTDIR="${1:-$PROJECT_ROOT/data/images}"
mkdir -p "$OUTDIR"

URL="$IMAGE_SOURCE_URL"
FILENAME="$IMAGE_COMPRESSED_FILENAME"
FILEPATH="$OUTDIR/$FILENAME"

echo "Downloading Armbian image for S905W..."
echo "URL: $URL"
echo "Output: $FILEPATH"

if [ -f "$FILEPATH" ]; then
    echo "File already exists. Skipping download."
else
    if command -v curl >/dev/null 2>&1; then
        curl -L -o "$FILEPATH" "$URL"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$FILEPATH" "$URL"
    else
        echo "Error: Neither curl nor wget found." >&2
        exit 1
    fi
fi

echo "Download complete."
ls -lh "$FILEPATH"
