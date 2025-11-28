#!/bin/bash

##############################################################################
# Amlogic S905W Device Setup Script
# Complete setup from flashed device to running persistent service
##############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

##############################################################################
# Configuration
##############################################################################

# User-provided device IP
DEVICE_IP="${1:-}"
DEVICE_USER="${SSH_USER:-root}"
DEVICE_PORT="${SSH_PORT:-22}"

# Try to load centralized configuration if present
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/scripts/load_config.sh" ]; then
    # shellcheck disable=SC1090
    source "$SCRIPT_DIR/scripts/load_config.sh"
fi

# Use configuration-driven or fallback defaults
BINARY_SOURCE_PATH="${BINARY_SOURCE_PATH:-build-aarch64/monitor_service}"
REMOTE_BIN_PATH="${SERVICE_BINARY:-/opt/monitor_service}"
LOG_PATH="${SERVICE_LOG_PATH:-/var/log/monitor.log}"

echo "Using binary source: $BINARY_SOURCE_PATH"
echo "Using remote install path: $REMOTE_BIN_PATH"
echo "Using log path: $LOG_PATH"

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

check_prerequisites() {
    print_header "Step 1: Checking Prerequisites"
    
    # Check if binary exists
    if [ ! -f "$BINARY_SOURCE_PATH" ]; then
        print_error "Binary not found: $BINARY_SOURCE_PATH"
        echo "Please build the project first:"
        echo "  cmake -DCMAKE_TOOLCHAIN_FILE=CMakeToolchain.cmake -B build-aarch64 ."
        echo "  cmake --build build-aarch64"
        exit 1
    fi
    print_success "Binary found: $BINARY_SOURCE_PATH"
    
    # Check if device IP provided
    if [ -z "$DEVICE_IP" ]; then
        print_error "Device IP not provided"
        echo "Usage: $0 <DEVICE_IP>"
        echo ""
        echo "Example: $0 192.168.1.100"
        exit 1
    fi
    print_success "Device IP: $DEVICE_IP"
}

test_ssh_connection() {
    print_header "Step 2: Testing SSH Connection"
    
    print_step "Connecting to $DEVICE_USER@$DEVICE_IP (port $DEVICE_PORT)..."
    
    if ssh -o ConnectTimeout=5 -p "$DEVICE_PORT" "$DEVICE_USER@$DEVICE_IP" "echo 'SSH connection successful'" > /dev/null 2>&1; then
        print_success "SSH connection working"
    else
        print_error "Cannot connect via SSH"
        echo ""
        echo "Troubleshooting:"
        echo "1. Verify device IP: $DEVICE_IP"
        echo "2. Verify SSH is enabled on device"
        echo "3. Try manual connection: ssh root@$DEVICE_IP"
        exit 1
    fi
}

verify_system_files() {
    print_header "Step 3: Verifying System Files on Device"
    
    print_step "Checking required system files..."
    
    ssh "$DEVICE_USER@$DEVICE_IP" << 'EOF'
    
    # Check /proc/meminfo
    if [ -f /proc/meminfo ]; then
        echo "✓ /proc/meminfo exists"
    else
        echo "✗ /proc/meminfo missing (CRITICAL)"
        exit 1
    fi
    
    # Check /proc/mounts
    if [ -f /proc/mounts ]; then
        echo "✓ /proc/mounts exists"
    else
        echo "✗ /proc/mounts missing (CRITICAL)"
        exit 1
    fi
    
    # Check thermal zones (optional)
    if [ -d /sys/class/thermal ]; then
        THERMAL_COUNT=$(ls /sys/class/thermal | wc -l)
        echo "✓ /sys/class/thermal exists ($THERMAL_COUNT entries)"
    else
        echo "⚠ /sys/class/thermal not found (CPU temp will be unavailable)"
    fi
EOF
    
    print_success "System files verified"
}

transfer_binary() {
    print_header "Step 4: Transferring Binary to Device"
    
    print_step "Copying $BINARY_SOURCE_PATH to $DEVICE_USER@$DEVICE_IP:/tmp/..."
    
    if scp -P "$DEVICE_PORT" "$BINARY_SOURCE_PATH" "$DEVICE_USER@$DEVICE_IP:/tmp/monitor_service"; then
        print_success "Binary transferred"
    else
        print_error "Failed to transfer binary"
        exit 1
    fi
    
    # Verify transfer
    REMOTE_SIZE=$(ssh -p "$DEVICE_PORT" "$DEVICE_USER@$DEVICE_IP" "ls -lh /tmp/monitor_service | awk '{print \$5}'")
    LOCAL_SIZE=$(ls -lh "$BINARY_SOURCE_PATH" | awk '{print $5}')
    
    echo "  Local size:  $LOCAL_SIZE"
    echo "  Remote size: $REMOTE_SIZE"
}

test_binary() {
    print_header "Step 5: Testing Binary on Device"
    
    print_step "Running monitoring service on device..."
    echo ""
    
    ssh -p "$DEVICE_PORT" "$DEVICE_USER@$DEVICE_IP" "/tmp/monitor_service"
    
    echo ""
    print_success "Binary executed successfully"
}

setup_systemd_service() {
    print_header "Step 6: Setting Up Systemd Service"
    
    print_step "Creating systemd service file..."

    # Create service file (use REMOTE_BIN_PATH variable)
    cat > /tmp/monitor.service <<EOF
[Unit]
Description=Amlogic S905W System Monitoring Service
Documentation=file://$REMOTE_BIN_PATH
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=$REMOTE_BIN_PATH
StandardOutput=journal
StandardError=journal
SyslogIdentifier=monitor
User=root

[Install]
WantedBy=multi-user.target
EOF

    print_step "Transferring service file to device..."
    scp -P "$DEVICE_PORT" /tmp/monitor.service "$DEVICE_USER@$DEVICE_IP:/tmp/"
    
    print_step "Installing service on device..."
# Use unquoted heredoc delimiter so local variables expand into remote commands
    ssh -p "$DEVICE_PORT" "$DEVICE_USER@$DEVICE_IP" << SSHCMD
# Copy binary to permanent location
cp /tmp/monitor_service $REMOTE_BIN_PATH
chmod +x $REMOTE_BIN_PATH

# Install service file
cp /tmp/monitor.service /etc/systemd/system/
chmod 644 /etc/systemd/system/monitor.service

# Reload systemd
systemctl daemon-reload

# Enable service to start on boot
systemctl enable monitor.service

# Start service immediately
systemctl start monitor.service

echo "✓ Service installed and started"
SSHCMD

    print_success "Systemd service configured"
}

verify_service() {
    print_header "Step 7: Verifying Service"
    
    print_step "Checking service status..."
    
    ssh -p "$DEVICE_PORT" "$DEVICE_USER@$DEVICE_IP" "systemctl status monitor.service --no-pager"
    
    print_step "Checking recent logs..."
    ssh -p "$DEVICE_PORT" "$DEVICE_USER@$DEVICE_IP" "journalctl -u monitor.service -n 10 --no-pager"
    
    print_success "Service verification complete"
}

    print_summary() {
    print_header "Setup Complete! ✅"
    
    echo "Your Amlogic S905W monitoring service is now running!"
    echo ""
    echo "Device Information:"
    echo "  IP Address:        $DEVICE_IP"
    echo "  Binary Location:   $REMOTE_BIN_PATH"
    echo "  Service Name:      monitor.service"
    echo ""
    echo "Useful Commands:"
    echo ""
    echo "  View service status:"
    echo "    ssh root@$DEVICE_IP \"systemctl status monitor.service\""
    echo ""
    echo "  View live logs:"
    echo "    ssh root@$DEVICE_IP \"journalctl -u monitor.service -f\""
    echo ""
    echo "  Run monitoring service manually:"
    echo "    ssh root@$DEVICE_IP \"$REMOTE_BIN_PATH\""
    echo ""
    echo "  Stop service:"
    echo "    ssh root@$DEVICE_IP \"systemctl stop monitor.service\""
    echo ""
    echo "  Restart service:"
    echo "    ssh root@$DEVICE_IP \"systemctl restart monitor.service\""
    echo ""
    echo "The service will automatically:"
    echo "  ✓ Start on device boot"
    echo "  ✓ Log output to systemd journal"
    echo "  ✓ Can be monitored via SSH"
    echo ""
}

##############################################################################
# Main Execution
##############################################################################

main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║   Amlogic S905W Persistent Service Setup               ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    check_prerequisites
    test_ssh_connection
    verify_system_files
    transfer_binary
    test_binary
    setup_systemd_service
    verify_service
    print_summary
}

# Run main function
main "$@"
