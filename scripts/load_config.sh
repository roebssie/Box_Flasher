#!/usr/bin/env bash

##############################################################################
# Configuration Loader
# Sources all configuration files and exports variables
##############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="$PROJECT_ROOT/data"
CONFIG_DIR="$DATA_DIR/config"

# Trim helper
_trim() {
    local var="$1"
    # Remove leading/trailing whitespace
    var="$(echo -n "$var" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    echo "$var"
}

# Function to load a config file (key=value like), robust to spaces and quotes
load_config_file() {
    local config_file="$1"
    local config_name
    config_name="$(basename "$config_file" .config)"

    if [ ! -f "$config_file" ]; then
        echo "⚠ Not found: $config_file" >&2
        return 1
    fi

    while IFS= read -r line || [ -n "$line" ]; do
        # Strip comments and whitespace
        line="$(echo "$line" | sed -e 's/#.*$//')"
        line="$(echo -n "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        [ -z "$line" ] && continue

        # Support export KEY=VAL or KEY=VAL
        if [[ "$line" =~ ^export[[:space:]]+(.+) ]]; then
            line="${BASH_REMATCH[1]}"
        fi

        # Split key/value on first '='
        if [[ "$line" == *=* ]]; then
            key="${line%%=*}"
            value="${line#*=}"
            key="$(_trim "$key")"
            value="$(_trim "$value")"
            # Strip surrounding double-quotes and single-quotes
            value="${value#\"}"; value="${value%\"}"
            value="${value#\'}"; value="${value%\'}"
            # Strip trailing inline comments (after value)
            value="$(echo "$value" | sed -e 's/[[:space:]]*#.*$//')"
            if [ -n "$key" ]; then
                export "$key=$value"
            fi
        fi
    done < "$config_file"

    echo "✓ Loaded: $config_name" >&2
}

# Export base directories (re-export if .env provides overrides)
export PROJECT_ROOT
export DATA_DIR
export CONFIG_DIR
export IMAGES_DIR="$DATA_DIR/images"
export RESOURCES_DIR="$DATA_DIR/resources"
export CACHE_DIR="$DATA_DIR/cache"
export LOGS_DIR="$DATA_DIR/logs"

# Load config files (if missing, loader prints a warning)
load_config_file "$CONFIG_DIR/device.config" || true
load_config_file "$CONFIG_DIR/build.config" || true
load_config_file "$CONFIG_DIR/flashing.config" || true
load_config_file "$CONFIG_DIR/service.config" || true

# Load local .env if exists (has precedence)
if [ -f "$DATA_DIR/.env" ]; then
    set -a
    # shellcheck disable=SC1090
    source "$DATA_DIR/.env"
    set +a
    echo "✓ Loaded: .env" >&2
fi

# Normalize common variables so scripts can rely on them
# Prefer explicit variables already exported, otherwise fallback to similar keys
IMAGES_DIR="${IMAGES_DIR:-${IMAGE_STORAGE_PATH:-$DATA_DIR/images}}"
CACHE_DIR="${CACHE_DIR:-${IMAGE_CACHE_PATH:-$DATA_DIR/cache}}"
LOGS_DIR="${LOGS_DIR:-${LOG_FILE_PATH:-$DATA_DIR/logs}}"
BUILD_DIR="${BUILD_DIR:-${BUILD_ARTIFACT_DIR:-build-aarch64}}"
SERVICE_BINARY="${SERVICE_BINARY:-${BINARY_INSTALL_PATH:-/opt/monitor_service}}"
export IMAGES_DIR CACHE_DIR LOGS_DIR BUILD_DIR SERVICE_BINARY

# Image naming aliases for older scripts
IMAGE_FILE="${IMAGE_FILE:-${IMAGE_FILENAME:-}}"
IMAGE_COMPRESSED_FILENAME="${IMAGE_COMPRESSED_FILENAME:-${IMAGE_GZ_FILENAME:-${IMAGE_FILE}.gz}}"
IMAGE_URL="${IMAGE_URL:-${IMAGE_SOURCE_URL:-}}"
export IMAGE_FILE IMAGE_COMPRESSED_FILENAME IMAGE_URL

echo "" >&2
echo "Configuration loaded. Available variables:" >&2
echo "  PROJECT_ROOT=$PROJECT_ROOT" >&2
echo "  DATA_DIR=$DATA_DIR" >&2
echo "  IMAGES_DIR=$IMAGES_DIR" >&2
echo "  LOGS_DIR=$LOGS_DIR" >&2
echo "  DEVICE_NAME=${DEVICE_NAME:-<unset>}" >&2
echo "  BUILD_DIR=${BUILD_DIR:-build-aarch64}" >&2
