#!/bin/bash

##############################################################################
# Data Initialization Script
# Sets up data directory structure and loads configuration
##############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$PROJECT_ROOT/data"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}→${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Create required directories
print_header "Creating data directory structure..."

mkdir -p "$DATA_DIR"/{images,config,resources,cache/{downloaded,build,backups},logs}

print_success "Data directories created"

# Verify configuration files exist
print_header "Verifying configuration files..."

CONFIG_FILES=(
    "device.config"
    "build.config"
    "flashing.config"
    "service.config"
)

for config_file in "${CONFIG_FILES[@]}"; do
    if [ -f "$DATA_DIR/config/$config_file" ]; then
        print_success "Found: $config_file"
    else
        echo "⚠️  Missing: $config_file"
    fi
done

# Create .gitignore for data directory
print_header "Creating .gitignore for data directory..."

cat > "$DATA_DIR/.gitignore" << 'EOF'
# OS Images - Large files
*.img
*.img.gz
*.iso

# Cache files
cache/downloaded/**
cache/build/**
cache/backups/**

# Logs
logs/**

# Temporary files
*.tmp
*.lock
*.pid

# Environment files
.env
.env.local

# OS-specific
.DS_Store
Thumbs.db
EOF

print_success ".gitignore created"

# Create environment file template
print_header "Creating environment file template..."

cat > "$DATA_DIR/.env.example" << 'EOF'
# Project directories
PROJECT_ROOT=$(pwd)
DATA_DIR=$PROJECT_ROOT/data
IMAGES_DIR=$DATA_DIR/images
CONFIG_DIR=$DATA_DIR/config
RESOURCES_DIR=$DATA_DIR/resources
CACHE_DIR=$DATA_DIR/cache
LOGS_DIR=$DATA_DIR/logs

# Device configuration
DEVICE_IP=192.168.1.100
DEVICE_USER=root
DEVICE_PORT=22

# Build configuration
BUILD_DIR=build-aarch64
BINARY_NAME=monitor_service

# Image configuration
IMAGE_FILE=CoreELEC-Amlogic.aarch64-latest.img
IMAGE_URL=https://releases.coreelec.org/CoreELEC-Amlogic.aarch64-latest.img.gz

# Logging
LOG_LEVEL=INFO
LOG_VERBOSE=yes
EOF

print_success ".env.example created"

# Print data directory structure
echo ""
print_header "Data Directory Structure:"
echo ""
tree -L 2 "$DATA_DIR" 2>/dev/null || find "$DATA_DIR" -type d | head -20
echo ""

# Print configuration locations
echo ""
print_header "Configuration Locations:"
echo ""
echo "  Device config:   $DATA_DIR/config/device.config"
echo "  Build config:    $DATA_DIR/config/build.config"
echo "  Flashing config: $DATA_DIR/config/flashing.config"
echo "  Service config:  $DATA_DIR/config/service.config"
echo ""

# Print environment setup
echo ""
print_header "To use these configurations in your scripts:"
echo ""
echo "  source data/.env"
echo "  source \"${SCRIPT_DIR}/load_config.sh\""
echo ""

print_success "Data initialization complete!"
