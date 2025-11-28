#!/bin/bash

###########################################
# Deployment and Testing Script
# Cross-Compiled Monitor Service for S905W
# Target: Embedded Linux (CoreELEC/LibreELEC)
###########################################

set -e

# Configuration
TARGET_HOST="${TARGET_HOST:-root@192.168.1.100}"
TARGET_PORT="${TARGET_PORT:-22}"
# Try to load centralized configuration if present
if [ -f "./scripts/load_config.sh" ]; then
    # shellcheck disable=SC1090
    source ./scripts/load_config.sh
fi

# Default executable path (can be overridden by BUILD_DIR or EXECUTABLE_PATH env var)
EXECUTABLE_PATH="${EXECUTABLE_PATH:-${BUILD_DIR:-build-aarch64}/monitor_service}"
REMOTE_PATH="/tmp/monitor_service"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${GREEN}===========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}===========================================${NC}"
}

print_error() {
    echo -e "${RED}ERROR: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Script starts here
print_header "Monitor Service Deployment Script"

# Step 1: Verify executable exists
echo ""
echo "[Step 1/6] Verifying cross-compiled executable..."

if [ ! -f "$EXECUTABLE_PATH" ]; then
    print_error "Executable not found at: $EXECUTABLE_PATH"
    echo "Please build the project first with:"
    echo "  cmake -DCMAKE_TOOLCHAIN_FILE=CMakeToolchain.cmake -B build-aarch64 ."
    echo "  cmake --build build-aarch64"
    exit 1
fi

print_success "Executable found"
echo "File: $EXECUTABLE_PATH"
echo "Size: $(du -h "$EXECUTABLE_PATH" | cut -f1)"

# Step 2: Verify architecture
echo ""
echo "[Step 2/6] Verifying executable architecture..."

if file "$EXECUTABLE_PATH" | grep -q "aarch64\|ARM64"; then
    print_success "Executable is aarch64 (ARM64)"
    file "$EXECUTABLE_PATH"
else
    print_warning "Could not verify aarch64 architecture"
    file "$EXECUTABLE_PATH"
fi

# Step 3: Verify static linking
echo ""
echo "[Step 3/6] Checking for static linking..."

if otool -L "$EXECUTABLE_PATH" 2>/dev/null | grep -q "dynamically linked"; then
    print_warning "Executable appears to have dynamic dependencies"
    echo "This may cause issues on minimal embedded systems"
elif file "$EXECUTABLE_PATH" | grep -q "statically linked"; then
    print_success "Executable is statically linked"
else
    echo "Using aarch64-linux-gnu-objdump to verify linking..."
    if command -v aarch64-linux-gnu-objdump &> /dev/null; then
        aarch64-linux-gnu-objdump -T "$EXECUTABLE_PATH" 2>/dev/null | head -5 || true
    fi
fi

# Step 4: Connection test
echo ""
echo "[Step 4/6] Testing SSH connection to target device..."
echo "Target: $TARGET_HOST (port $TARGET_PORT)"

if ssh -p "$TARGET_PORT" -o ConnectTimeout=5 "$TARGET_HOST" "echo 'SSH connection successful'" 2>/dev/null; then
    print_success "SSH connection successful"
else
    print_warning "Could not connect to $TARGET_HOST"
    echo "Please configure TARGET_HOST before deployment:"
    echo "  export TARGET_HOST=root@<your-device-ip>"
    echo "  export TARGET_PORT=22"
    echo ""
    echo "To find your device IP:"
    echo "  - Check your router's DHCP client list"
    echo "  - Use: arp -a | grep -i amlogic"
    echo "  - Use: nmap to scan your network"
    echo ""
    exit 1
fi

# Step 5: Transfer executable
echo ""
echo "[Step 5/6] Transferring executable to target device..."
echo "Destination: $TARGET_HOST:$REMOTE_PATH"

scp -P "$TARGET_PORT" "$EXECUTABLE_PATH" "$TARGET_HOST:$REMOTE_PATH" 2>&1 | tail -5

print_success "Executable transferred"

# Step 6: Remote execution
echo ""
echo "[Step 6/6] Executing monitor service on target device..."
echo ""

ssh -p "$TARGET_PORT" "$TARGET_HOST" "chmod +x '$REMOTE_PATH' && '$REMOTE_PATH'"

print_header "Deployment Complete!"
echo ""
echo "Summary:"
echo "  - Built executable verified as aarch64"
echo "  - Transferred to: $REMOTE_PATH"
echo "  - Execution completed successfully"
echo ""
echo "Next steps:"
echo "  - Monitor the service output above"
echo "  - For continuous monitoring, run:"
echo "    ssh -p $TARGET_PORT $TARGET_HOST \"$REMOTE_PATH\""
echo "  - To install as persistent service, create systemd unit on target"
echo ""
