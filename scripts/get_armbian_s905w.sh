#!/usr/bin/env bash
##############################################################################
# Armbian Image Downloader for Amlogic S905W
# 
# Downloads and prepares Armbian images for S905W devices.
# 
# IMPORTANT: Armbian images are RAW DISK IMAGES (.img) that must be written
# to SD card or USB drive using dd/balenaEtcher/Rufus - they are NOT compatible
# with the Amlogic USB Burning Tool (which requires Amlogic-packed firmware).
#
# Usage:
#   ./scripts/get_armbian_s905w.sh [output-dir]
#
# Configuration:
#   Reads from data/config/flashing.config for image URLs and settings
##############################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step()    { echo -e "${BLUE}→${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error()   { echo -e "${RED}✗${NC} $1" >&2; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }

##############################################################################
# Configuration Loading
##############################################################################

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load configuration from flashing.config
CONFIG_FILE="$PROJECT_ROOT/data/config/flashing.config"
if [ -f "$CONFIG_FILE" ]; then
    print_step "Loading configuration from $CONFIG_FILE"
    # shellcheck source=../data/config/flashing.config
    source "$CONFIG_FILE"
else
    print_error "Config file not found: $CONFIG_FILE"
    print_step "Using default values..."
fi

# Load .env overrides if present
ENV_FILE="$PROJECT_ROOT/data/.env"
if [ -f "$ENV_FILE" ]; then
    print_step "Loading overrides from $ENV_FILE"
    # shellcheck source=/dev/null
    source "$ENV_FILE"
fi

##############################################################################
# Configuration Variables (with defaults)
##############################################################################

# Output directory (command line arg or default)
OUTDIR="${1:-${PROJECT_ROOT}/data/images}"

# Image source URL and filenames
URL="${IMAGE_SOURCE_URL:-https://github.com/ophub/amlogic-s9xxx-armbian/releases/download/Armbian_bullseye_arm64_server_2025.11/Armbian_25.11.0_amlogic_s905w_bullseye_6.1.158_server_2025.11.11.img.gz}"
COMPRESSED_FILENAME="${IMAGE_COMPRESSED_FILENAME:-Armbian_25.11.0_amlogic_s905w_bullseye_6.1.158_server_2025.11.11.img.gz}"
UNCOMPRESSED_FILENAME="${IMAGE_FILENAME:-Armbian_25.11.0_amlogic_s905w_bullseye_6.1.158_server_2025.11.11.img}"

# Verification settings
VERIFY_DOWNLOAD="${VERIFY_IMAGE_AFTER_DOWNLOAD:-yes}"

##############################################################################
# Helper Functions
##############################################################################

check_dependencies() {
    local missing=()
    
    # Check for download tools
    if ! command -v curl &>/dev/null && ! command -v wget &>/dev/null; then
        missing+=("curl or wget")
    fi
    
    # Check for decompression tools
    if ! command -v gunzip &>/dev/null && ! command -v gzip &>/dev/null; then
        missing+=("gzip/gunzip")
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        print_error "Missing required tools: ${missing[*]}"
        exit 1
    fi
}

download_file() {
    local url="$1"
    local output="$2"
    
    print_step "Downloading: $(basename "$output")"
    print_step "From: $url"
    
    if command -v curl &>/dev/null; then
        curl -L --progress-bar -o "$output" "$url"
    elif command -v wget &>/dev/null; then
        wget --show-progress -O "$output" "$url"
    else
        print_error "No download tool available (need curl or wget)"
        return 1
    fi
}

verify_gzip() {
    local file="$1"
    
    if ! gzip -t "$file" 2>/dev/null; then
        return 1
    fi
    return 0
}

decompress_image() {
    local compressed="$1"
    local uncompressed="$2"
    
    print_step "Decompressing image..."
    
    # Keep original compressed file (-k flag)
    if command -v gunzip &>/dev/null; then
        gunzip -k -f "$compressed"
    elif command -v gzip &>/dev/null; then
        gzip -dk -f "$compressed"
    else
        print_error "No decompression tool available"
        return 1
    fi
    
    print_success "Decompressed to: $(basename "$uncompressed")"
}

get_file_size() {
    local file="$1"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        stat -f%z "$file" 2>/dev/null || echo "0"
    else
        stat -c%s "$file" 2>/dev/null || echo "0"
    fi
}

format_size() {
    local size="$1"
    if [ "$size" -gt 1073741824 ]; then
        echo "$(( size / 1073741824 )) GB"
    elif [ "$size" -gt 1048576 ]; then
        echo "$(( size / 1048576 )) MB"
    elif [ "$size" -gt 1024 ]; then
        echo "$(( size / 1024 )) KB"
    else
        echo "$size bytes"
    fi
}

##############################################################################
# Main Script
##############################################################################

main() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  Armbian S905W Image Downloader                            ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Important notice about image format
    print_warning "IMPORTANT: Armbian images are RAW DISK IMAGES"
    print_warning "They must be written to SD card/USB drive using:"
    print_warning "  - dd (Linux/macOS)"
    print_warning "  - balenaEtcher (cross-platform)"
    print_warning "  - Rufus (Windows)"
    print_warning ""
    print_warning "These images are NOT compatible with Amlogic USB Burning Tool!"
    print_warning "The USB Burning Tool requires Amlogic-packed firmware (.img from Android)."
    echo ""
    
    # Check dependencies
    check_dependencies
    
    # Create output directory
    print_step "Output directory: $OUTDIR"
    mkdir -p "$OUTDIR"
    
    local compressed_path="$OUTDIR/$COMPRESSED_FILENAME"
    local uncompressed_path="$OUTDIR/$UNCOMPRESSED_FILENAME"
    
    # Check if uncompressed image already exists
    if [ -f "$uncompressed_path" ]; then
        local size
        size=$(get_file_size "$uncompressed_path")
        print_success "Image already exists: $UNCOMPRESSED_FILENAME ($(format_size "$size"))"
        echo ""
        echo -e "${GREEN}Ready to flash!${NC}"
        echo "Use one of these methods to write to SD card/USB:"
        echo "  sudo dd if=\"$uncompressed_path\" of=/dev/sdX bs=4M status=progress"
        echo "  Or use balenaEtcher / Rufus"
        return 0
    fi
    
    # Check if compressed image exists and is valid
    if [ -f "$compressed_path" ]; then
        print_step "Found compressed image: $COMPRESSED_FILENAME"
        
        if [ "$VERIFY_DOWNLOAD" = "yes" ]; then
            print_step "Verifying archive integrity..."
            if verify_gzip "$compressed_path"; then
                print_success "Archive is valid"
            else
                print_warning "Archive appears corrupted, re-downloading..."
                rm -f "$compressed_path"
            fi
        fi
    fi
    
    # Download if compressed image doesn't exist
    if [ ! -f "$compressed_path" ]; then
        echo ""
        print_step "Starting download..."
        print_warning "This may take a while depending on your connection speed."
        echo ""
        
        if ! download_file "$URL" "$compressed_path"; then
            print_error "Download failed!"
            rm -f "$compressed_path"
            exit 1
        fi
        
        # Verify downloaded file
        if [ "$VERIFY_DOWNLOAD" = "yes" ]; then
            print_step "Verifying downloaded archive..."
            if ! verify_gzip "$compressed_path"; then
                print_error "Downloaded file is corrupted!"
                print_step "Please check your internet connection and try again."
                rm -f "$compressed_path"
                exit 1
            fi
            print_success "Download verified successfully"
        fi
    fi
    
    # Decompress if needed
    if [ ! -f "$uncompressed_path" ]; then
        decompress_image "$compressed_path" "$uncompressed_path"
    fi
    
    # Final status
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}  Download Complete!                                         ${GREEN}║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local size
    size=$(get_file_size "$uncompressed_path")
    echo "Image: $uncompressed_path"
    echo "Size:  $(format_size "$size")"
    echo ""
    
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "1. Insert SD card (8GB+ recommended)"
    echo "2. Find device name (e.g., /dev/sdb on Linux, /dev/disk2 on macOS)"
    echo "3. Flash the image:"
    echo ""
    echo "   Linux:"
    echo "     sudo dd if=\"$uncompressed_path\" of=/dev/sdX bs=4M status=progress conv=fsync"
    echo ""
    echo "   macOS:"
    echo "     sudo dd if=\"$uncompressed_path\" of=/dev/rdiskN bs=4m"
    echo ""
    echo "   Windows: Use balenaEtcher or Rufus"
    echo ""
    echo -e "${YELLOW}Boot Instructions:${NC}"
    echo "1. Insert flashed SD card into S905W device"
    echo "2. Connect USB-A to USB-A cable between PC and device's USB port"
    echo "3. Hold reset/boot button while powering on"
    echo "4. Device should boot from SD card"
    echo ""
}

# Run main function
main "$@"
