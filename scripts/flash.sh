#!/bin/bash

##############################################################################
# Updated Flash Script Using Data Directory
# Reads image from data/images, logs to data/logs
##############################################################################

set -e

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/load_config.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  $1"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "${YELLOW}→${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Logging setup
LOG_FILE="$LOGS_DIR/flashing.log"
mkdir -p "$(dirname "$LOG_FILE")"

log_message() {
    local msg="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $msg" >> "$LOG_FILE"
}

flash_device() {
    local image_file="$1"
    
    if [ ! -f "$image_file" ]; then
        print_error "Image not found: $image_file"
        return 1
    fi
    
    print_header "Flashing S905W with $IMAGE_FILE"
    
    log_message "Starting flash operation with $image_file"
    
    # Check if flashing tool is available
    if command -v aml_usb_flashing_tool &> /dev/null; then
        print_step "Using Amlogic USB Flashing Tool..."
        aml_usb_flashing_tool --image "$image_file" --device s905w | tee -a "$LOG_FILE"
        log_message "Flash operation completed"
        return 0
    fi
    
    # Fallback to manual dd method
    print_step "Using manual dd flashing method..."
    
    # List USB devices
    diskutil list external | grep "^/dev"
    
    read -p "Enter USB device path: " usb_device
    
    if [ -z "$usb_device" ]; then
        print_error "No device specified"
        return 1
    fi
    
    # Verify and flash
    diskutil unmountDisk "$usb_device" 2>/dev/null || true
    
    log_message "Flashing $image_file to $usb_device"
    
    sudo dd if="$image_file" of="/dev/r${usb_device#/dev/}" bs=4m status=progress 2>&1 | tee -a "$LOG_FILE"
    
    sync
    diskutil eject "$usb_device"
    
    print_success "Flashing completed!"
    log_message "Flash operation completed successfully"
}

# Main execution
main() {
    print_header "S905W Flashing Tool - Data Directory Version"
    
    echo "Configuration loaded:"
    echo "  Project: $PROJECT_ROOT"
    echo "  Images:  $IMAGES_DIR"
    echo "  Logs:    $LOGS_DIR"
    echo "  Device:  $DEVICE_NAME"
    echo ""
    
    # Check if image exists
    if [ ! -f "$IMAGES_DIR/$IMAGE_FILE" ]; then
        print_error "Image not found: $IMAGES_DIR/$IMAGE_FILE"
        echo ""
        echo "To download image, run:"
        echo "  ./scripts/get_armbian_s905w.sh"
        echo ""
        echo "Or manually:"
        echo "  cd $IMAGES_DIR"
        echo "  wget $IMAGE_URL"
        echo "  gunzip $IMAGE_COMPRESSED_FILENAME"
        return 1
    fi
    
    print_success "Found image: $IMAGE_FILE"
    ls -lh "$IMAGES_DIR/$IMAGE_FILE"
    
    flash_device "$IMAGES_DIR/$IMAGE_FILE"
    
    echo ""
    echo "Log file: $LOG_FILE"
}

main "$@"
