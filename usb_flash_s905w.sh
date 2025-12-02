#!/bin/bash

##############################################################################
# Amlogic S905W USB Direct Flashing Script for macOS
# One-stop solution for downloading and flashing CoreELEC to S905W via USB
##############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
# Attempt to load centralized project configuration if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/scripts/load_config.sh" ]; then
    # shellcheck disable=SC1090
    source "$SCRIPT_DIR/scripts/load_config.sh"
fi

# Defaults (can be overridden by data/config/flashing.config or .env)
WORK_DIR="${IMAGES_DIR:-$HOME/S905W_Flashing}"
IMG_URL="${IMAGE_SOURCE_URL:-https://github.com/ophub/amlogic-s9xxx-armbian/releases/download/Armbian_bullseye_arm64_server_2025.11/Armbian_25.11.0_amlogic_s905w_bullseye_6.1.158_server_2025.11.11.img.gz}"
IMG_FILENAME="${IMAGE_FILENAME:-Armbian_25.11.0_amlogic_s905w_bullseye_6.1.158_server_2025.11.11.img}"
IMG_GZ_FILENAME="${IMAGE_COMPRESSED_FILENAME:-${IMG_FILENAME}.gz}"

##############################################################################
# Functions
##############################################################################

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

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

check_prerequisites() {
    print_header "Step 1: Checking Prerequisites"
    
    # Check macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script requires macOS"
        exit 1
    fi
    print_success "Running on macOS"
    
    # Check Homebrew
    if ! command -v brew &> /dev/null; then
        print_error "Homebrew not installed"
        echo "Install from: https://brew.sh"
        exit 1
    fi
    print_success "Homebrew installed"
    
    # Check for USB tools
    if ! command -v libusb-config &> /dev/null; then
        print_warning "libusb not installed. Installing..."
        brew install libusb libftdi 2>/dev/null || true
    fi
    print_success "USB tools available"
}

setup_working_directory() {
    print_header "Step 2: Setting Up Working Directory"
    
    if [ ! -d "$WORK_DIR" ]; then
        print_step "Creating directory: $WORK_DIR"
        mkdir -p "$WORK_DIR"
    fi
    
    cd "$WORK_DIR"
    print_success "Working directory: $WORK_DIR"
}

download_image() {
    print_header "Step 3: Downloading Armbian Image"
    
    if [ -f "$WORK_DIR/$IMG_FILENAME" ]; then
        print_success "Image already exists: $IMG_FILENAME"
        return
    fi
    
    if [ -f "$WORK_DIR/$IMG_GZ_FILENAME" ]; then
        print_step "Found compressed image, extracting..."
        # Test gzip integrity before extracting. If corrupt or truncated, remove it so helper can redownload.
        if ! gzip -t "$WORK_DIR/$IMG_GZ_FILENAME" 2>/dev/null; then
            print_warning "Compressed image appears to be corrupted or incomplete: $IMG_GZ_FILENAME"
            print_step "Removing corrupt file so helper can re-download a fresh copy"
            rm -f "$WORK_DIR/$IMG_GZ_FILENAME"
        else
            gunzip -k "$WORK_DIR/$IMG_GZ_FILENAME"
            print_success "Image extracted"
            return
        fi
    fi
    
    print_step "Attempting to download Armbian image using helper script..."
    print_step "If automatic download fails, you can provide a local image in $WORK_DIR"

    # Try helper script first (will download the release asset into WORK_DIR)
    HELPER_PATH="${SCRIPT_DIR}/scripts/get_armbian_s905w.sh"
    if [ -f "$HELPER_PATH" ]; then
        if [ -x "$HELPER_PATH" ]; then
            if ! "$HELPER_PATH" "$WORK_DIR"; then
                print_warning "Auto-download helper failed — falling back to static URL"
            fi
        else
            # Try to run with bash if not executable (common on checked-out scripts)
            print_step "Found helper script but not executable — running with bash"
            if ! bash "$HELPER_PATH" "$WORK_DIR"; then
                print_warning "Auto-download helper failed when invoked with bash — falling back to static URL"
            fi
        fi
    else
        print_warning "Auto-download helper not found in scripts/ — falling back to static URL"
    fi

    # Inspect WORK_DIR for common artifacts
    IMG_GZ=$(ls -1 "$WORK_DIR"/Armbian_*.img.gz 2>/dev/null | tail -n1 || true)
    IMG_FILE=$(ls -1 "$WORK_DIR"/Armbian_*.img 2>/dev/null | tail -n1 || true)

    if [ -n "$IMG_GZ" ]; then
        print_step "Found compressed image: $IMG_GZ — extracting..."
        gunzip -k "$IMG_GZ"
        IMG_FILE="${IMG_GZ%.gz}"
        IMG_FILENAME="$(basename "$IMG_FILE")"
        print_success "Image ready: $IMG_FILE"
        return
    fi

    if [ -n "$IMG_FILE" ]; then
        print_success "Found image: $IMG_FILE"
        IMG_FILENAME="$(basename "$IMG_FILE")"
        return
    fi

    # Fallback: try static URL (older behavior)
    if [ -n "$IMG_URL" ]; then
        print_step "No release asset found locally — attempting static download from $IMG_URL"
        if ! wget -q --show-progress -O "$WORK_DIR/$IMG_GZ_FILENAME" "$IMG_URL"; then
            print_error "Download failed"
            exit 1
        fi
        gunzip "$WORK_DIR/$IMG_GZ_FILENAME"
        IMG_FILENAME="$IMG_FILENAME"
        print_success "Image ready: $WORK_DIR/$IMG_FILENAME"
        return
    fi

    print_error "No Armbian image found or downloaded. Place an image in $WORK_DIR and re-run."
    exit 1
    
    if ! wget -q --show-progress -O "$WORK_DIR/$IMG_GZ_FILENAME" "$IMG_URL"; then
        print_error "Download failed"
        exit 1
    fi
    
    print_success "Downloaded: $IMG_GZ_FILENAME"
    
    print_step "Extracting image..."
    gunzip "$WORK_DIR/$IMG_GZ_FILENAME"
    
    print_success "Image ready: $IMG_FILENAME"
}

check_usb_device() {
    print_header "Step 4: Checking USB Device"
    
    echo "Checking for Amlogic device connected via USB..."
    echo ""
    
    # Check for Amlogic vendor ID
    if system_profiler SPUSBDataType 2>/dev/null | grep -q -i "amlogic\|1b8e"; then
        print_success "Amlogic device detected in USB mode!"
        echo ""
        echo "Device details:"
        system_profiler SPUSBDataType 2>/dev/null | grep -A 5 -B 2 -i amlogic | head -15
        return 0
    else
        print_warning "Amlogic device NOT detected in USB flashing mode"
        echo ""
        echo "Make sure:"
        echo "  1. S905W is connected via USB to your macBook"
        echo "  2. Device is in USB flashing mode (button/jumper held)"
        echo "  3. USB cable has data pins (not just power)"
        echo ""
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Aborted by user"
            exit 1
        fi
    fi
}

install_flashing_tool() {
    print_header "Step 5: Installing Flashing Tool"
    
    if command -v aml_usb_flashing_tool &> /dev/null; then
        print_success "Flashing tool already installed"
        return
    fi
    
    print_step "Installing Amlogic USB Flashing Tool..."
    
    if ! brew tap messense/amlogic-tools 2>/dev/null; then
        print_warning "Could not add tap, trying alternative method..."
    fi
    
    if brew install amlogic-usb-flashing-tool 2>/dev/null; then
        print_success "Flashing tool installed"
    else
        print_warning "Could not install flashing tool automatically"
        echo ""
        echo "You can still flash manually using direct USB method"
    fi
}

list_usb_devices() {
    print_header "Step 6: Available USB Devices"
    
    echo "Listed below are external USB devices:"
    echo ""
    
    diskutil list external | grep -E "^/dev/disk|FDisk_partition_scheme|GUID_partition_scheme"
    
    echo ""
    print_warning "Identify your S905W device from the list above"
    echo "Usually the smallest or most recently added device"
}

flash_device() {
    print_header "Step 7: Flashing S905W"
    
    # Try with flashing tool first
    if command -v aml_usb_flashing_tool &> /dev/null; then
        print_step "Using Amlogic USB Flashing Tool..."
        
        echo ""
        echo "DO NOT DISCONNECT USB CABLE DURING FLASHING"
        echo ""
        
        if aml_usb_flashing_tool --image "$IMG_FILENAME" --device s905w; then
            print_success "Flashing completed successfully!"
            return 0
        else
            print_warning "Flashing tool method failed, trying alternative..."
        fi
    fi
    
    # Manual flashing option
    print_step "Manual USB flashing method"
    echo ""
    echo "Available USB devices:"
    diskutil list external | grep "^/dev"
    echo ""
    
    read -p "Enter USB device path (e.g., /dev/disk3): " usb_device
    
    if [ -z "$usb_device" ]; then
        print_error "No device specified"
        exit 1
    fi
    
    # Validate device
    if ! diskutil list "$usb_device" &>/dev/null; then
        print_error "Invalid device: $usb_device"
        exit 1
    fi
    
    print_warning "FINAL WARNING"
    echo "This will ERASE all data on: $usb_device"
    echo "Device details:"
    diskutil list "$usb_device"
    echo ""
    
    read -p "Type 'yes' to proceed with flashing: " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_error "Aborted by user"
        exit 1
    fi
    
    print_step "Unmounting USB device..."
    diskutil unmountDisk "$usb_device" 2>/dev/null || true
    
    print_step "Flashing image (this takes 2-5 minutes)..."
    echo ""
    
    # Use raw device for faster access
    raw_device="/dev/r${usb_device#/dev/}"
    
    # Flash with dd
    if sudo dd if="$WORK_DIR/$IMG_FILENAME" of="$raw_device" bs=4m status=progress; then
        print_success "Flashing completed!"
        sync
        
        # Eject device
        print_step "Ejecting device..."
        diskutil eject "$usb_device" 2>/dev/null || true
        
        return 0
    else
        print_error "Flashing failed"
        diskutil eject "$usb_device" 2>/dev/null || true
        exit 1
    fi
}

post_flash() {
    print_header "Step 8: Post-Flashing Instructions"
    
    echo "Next steps:"
    echo ""
    echo "1. Disconnect USB cable from S905W"
    echo "2. Connect power supply to S905W (5V 2A+)"
    echo "3. Wait 3 minutes for device to boot"
    echo "4. Device should appear on network"
    echo ""
    echo "To find device IP:"
    echo "  ping -c 1 armbian.local"
    echo ""
    echo "Or check your router's DHCP table for 'armbian'"
    echo ""
}

deploy_service() {
    print_header "Step 9: Deploy Monitoring Service"
    
    read -p "Ready to deploy monitoring service? (y/n) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "After device is booted, run:"
        echo "  export DEVICE_IP='192.168.1.XXX'  # Replace with actual IP"
        echo "  cd /Users/roebssie/Desktop/Box_Flasher"
        echo "  ./setup_device.sh \$DEVICE_IP"
        echo ""
    fi
}

##############################################################################
# Main Execution
##############################################################################

main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║   Amlogic S905W USB Direct Flashing Tool              ║"
    echo "║   macOS with Armbian (Ophub)                          ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    check_prerequisites
    setup_working_directory
    download_image
    check_usb_device
    install_flashing_tool
    list_usb_devices
    
    read -p "Proceed with flashing? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        flash_device
        post_flash
    else
        print_warning "Flashing cancelled"
        echo ""
        echo "You can run this script again later:"
        echo "  bash $(basename "$0")"
        exit 0
    fi
}

# Run main function
main "$@"
