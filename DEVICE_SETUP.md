# 🔧 Amlogic S905W Device Setup & Persistent Service Guide

## 📋 Overview

This guide covers:
1. **Flashing the Amlogic S905W** with CoreELEC/LibreELEC
2. **Transferring the monitoring service binary**
3. **Setting up persistent execution** via systemd service
4. **Monitoring and logging**

---

## Part 1: Flash Amlogic S905W Device

### Prerequisites
- Amlogic S905W device
- MicroSD card (8GB+) or USB drive
- Card reader/USB adapter
- macOS with Homebrew installed
- ~30 minutes

### Step 1.1: Download CoreELEC/LibreELEC Image

**Option A: CoreELEC (Recommended for Amlogic)**
```bash
# Download CoreELEC for Amlogic S905W
# Go to: https://coreelec.org/
# Select: Amlogic → Latest Stable → aarch64 (ARM64)
# Or use wget:
cd ~/Downloads
wget https://releases.coreelec.org/CoreELEC-Amlogic.aarch64-latest.img.gz
gunzip CoreELEC-Amlogic.aarch64-latest.img.gz
```

**Option B: LibreELEC for Amlogic**
```bash
# Download LibreELEC for Amlogic S905W
# Go to: https://libreelec.tv/
# Select: Downloads → Amlogic → Latest → aarch64
cd ~/Downloads
wget https://releases.libreelec.tv/LibreELEC-Amlogic.aarch64-latest.img.gz
gunzip LibreELEC-Amlogic.aarch64-latest.img.gz
```

### Step 1.2: Identify SD Card Device

```bash
# Insert MicroSD card into reader
# List all disks
diskutil list

# Find your SD card (usually /dev/diskX where X is a number)
# Example output:
# /dev/disk0 (internal, physical):
#    ...
# /dev/disk1 (external, physical):
#    #:                    TYPE NAME                    SIZE
#    0:                              FDisk_partition_scheme    7.6 GB
# ↑ This is likely your SD card

export SD_DEVICE="/dev/disk1"  # Replace with YOUR device
```

⚠️ **CRITICAL:** Verify you have the correct device! Using the wrong device will erase your Mac!

### Step 1.3: Unmount SD Card

```bash
# Unmount (don't eject)
diskutil unmountDisk $SD_DEVICE

# Verify it's unmounted
diskutil list $SD_DEVICE
```

### Step 1.4: Flash Image to SD Card

```bash
# Use rdisk for faster writing (raw device)
# This takes 2-5 minutes
sudo dd if=~/Downloads/CoreELEC-Amlogic.aarch64-latest.img \
         of=/dev/r${SD_DEVICE#/dev/} \
         bs=4m \
         status=progress

# Wait for completion
sync
```

### Step 1.5: Eject SD Card

```bash
diskutil eject $SD_DEVICE
# Remove card from reader
```

### Step 1.6: Insert SD Card into S905W and Boot

1. Insert MicroSD card into S905W
2. Connect power to S905W
3. Connect S905W to network (Ethernet or WiFi)
4. Wait 2-3 minutes for first boot
5. Device should appear in your router's DHCP table

---

## Part 2: Initial Device Setup

### Step 2.1: Find Device IP Address

```bash
# Method 1: From router's DHCP table
# Check your router's admin panel (usually 192.168.1.1)
# Look for new device named "CoreELEC" or "LibreELEC"

# Method 2: Using mDNS (if enabled)
ping -c 1 coreelec.local

# Method 3: Scan your network (Linux/macOS)
brew install nmap
nmap -sn 192.168.1.0/24 | grep -i amlogic
```

Export your device IP:
```bash
export DEVICE_IP="192.168.1.XXX"  # Replace with actual IP
```

### Step 2.2: Enable SSH (if not already enabled)

**Method 1: Via Web Interface** (Recommended)
```bash
# Open CoreELEC Web UI
open "http://$DEVICE_IP:8080"
# Navigate to: Settings → System → Services → SSH → Enable
```

**Method 2: Via SSH Command** (requires SSH already enabled or direct access)
```bash
ssh root@$DEVICE_IP
```

### Step 2.3: Test SSH Connection

```bash
# First connection will ask about host key
ssh root@$DEVICE_IP

# Default password: (usually blank, just press Enter)
# or: "openelec" or "root"

# If successful, you'll see:
# CoreELEC:/home/root #
```

### Step 2.4: Verify System Files

```bash
# Verify required system files exist
ssh root@$DEVICE_IP "ls -la /proc/meminfo /proc/mounts /sys/class/thermal/"

# Expected output should show files/directories exist
```

---

## Part 3: Deploy Monitoring Service

### Step 3.1: Transfer Binary to Device

```bash
# From your macOS machine
export DEVICE_IP="192.168.1.XXX"

# Copy binary to device
scp build-aarch64/monitor_service root@$DEVICE_IP:/tmp/

# Verify transfer
ssh root@$DEVICE_IP "ls -lh /tmp/monitor_service"
```

### Step 3.2: Test Binary on Device

```bash
# Run the monitoring service
ssh root@$DEVICE_IP "/tmp/monitor_service"

# Expected output:
# === System Monitoring Service ===
# Target: Amlogic S905W Embedded Linux
# 
# CPU Temperature:
#   Temperature: XX.XX °C
# 
# RAM Usage:
#   Total:     XXX.XX MB
#   Free:      XXX.XX MB
#   Available: XXX.XX MB
#   Used:      XXX.XX MB (XX.XX%)
# 
# Storage Information:
# Mounted filesystems (storage points):
#   - /
#   - /boot
# 
# === Monitoring Service Completed ===
```

---

## Part 4: Set Up Persistent Service

### Option A: Systemd Service (Recommended)

#### Step 4A.1: Create Service File

```bash
# Copy binary to permanent location
ssh root@$DEVICE_IP "cp /tmp/monitor_service /usr/local/bin/monitor_service"
ssh root@$DEVICE_IP "chmod +x /usr/local/bin/monitor_service"

# Verify
ssh root@$DEVICE_IP "ls -lh /usr/local/bin/monitor_service"
```

#### Step 4A.2: Create Systemd Service Unit

```bash
# Create service file locally first
cat > /tmp/monitor.service << 'EOF'
[Unit]
Description=Amlogic S905W System Monitoring Service
Documentation=file:///usr/local/bin/monitor_service
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/monitor_service
StandardOutput=journal
StandardError=journal
SyslogIdentifier=monitor

# Run with reduced privileges (optional)
User=root
# TimeoutStartSec=30

# Restart on failure (optional)
# Restart=on-failure
# RestartSec=300

[Install]
WantedBy=multi-user.target
EOF

# Transfer to device
scp /tmp/monitor.service root@$DEVICE_IP:/etc/systemd/system/

# Verify
ssh root@$DEVICE_IP "ls -la /etc/systemd/system/monitor.service"
```

#### Step 4A.3: Enable and Start Service

```bash
# Reload systemd daemon
ssh root@$DEVICE_IP "systemctl daemon-reload"

# Enable service to start on boot
ssh root@$DEVICE_IP "systemctl enable monitor.service"

# Start service immediately
ssh root@$DEVICE_IP "systemctl start monitor.service"

# Check status
ssh root@$DEVICE_IP "systemctl status monitor.service"
```

#### Step 4A.4: View Logs

```bash
# View recent service output
ssh root@$DEVICE_IP "journalctl -u monitor.service -n 50"

# Watch logs in real-time
ssh root@$DEVICE_IP "journalctl -u monitor.service -f"

# View with timestamps
ssh root@$DEVICE_IP "journalctl -u monitor.service --since '10 minutes ago'"
```

---

### Option B: Cron Job (Simpler Alternative)

#### Step 4B.1: Set Up Cron Schedule

```bash
# Create crontab entry via SSH
ssh root@$DEVICE_IP << 'EOF'
# Add to root crontab
crontab -e

# Add this line (runs every 5 minutes):
*/5 * * * * /tmp/monitor_service >> /var/log/monitor.log 2>&1

# Or runs every hour:
# 0 * * * * /tmp/monitor_service >> /var/log/monitor.log 2>&1

# Or runs every 30 minutes:
# */30 * * * * /tmp/monitor_service >> /var/log/monitor.log 2>&1
EOF

# Verify cron is set
ssh root@$DEVICE_IP "crontab -l"

# View logs
ssh root@$DEVICE_IP "tail -f /var/log/monitor.log"
```

---

### Option C: Init Script (Manual Startup)

#### Step 4C.1: Create Init Script

```bash
# Create script that starts service at boot
cat > /tmp/monitor.init << 'EOF'
#!/bin/sh
### BEGIN INIT INFO
# Provides:          monitor
# Required-Start:    $local_fs $network
# Required-Stop:     $local_fs $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Amlogic S905W Monitoring Service
### END INIT INFO

case "$1" in
  start)
    echo "Starting monitoring service..."
    /tmp/monitor_service >> /var/log/monitor.log 2>&1 &
    ;;
  stop)
    echo "Stopping monitoring service..."
    pkill -f monitor_service
    ;;
  *)
    echo "Usage: $0 {start|stop}"
    exit 1
    ;;
esac

exit 0
EOF

# Transfer and install
scp /tmp/monitor.init root@$DEVICE_IP:/etc/init.d/monitor
ssh root@$DEVICE_IP "chmod +x /etc/init.d/monitor"
ssh root@$DEVICE_IP "update-rc.d monitor defaults"
```

---

## Part 5: Monitoring & Logging

### View Real-time Monitoring Output

```bash
# Method 1: One-time execution
ssh root@$DEVICE_IP "/tmp/monitor_service"

# Method 2: Watch logs if using systemd
ssh root@$DEVICE_IP "journalctl -u monitor.service -f"

# Method 3: View log file if using cron
ssh root@$DEVICE_IP "tail -f /var/log/monitor.log"
```

### Create Daily Log Rotation

```bash
# Create logrotate config
cat > /tmp/monitor.logrotate << 'EOF'
/var/log/monitor.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 0640 root root
}
EOF

# Install on device
scp /tmp/monitor.logrotate root@$DEVICE_IP:/etc/logrotate.d/monitor
ssh root@$DEVICE_IP "chmod 644 /etc/logrotate.d/monitor"
```

---

## Part 6: Advanced Configuration

### Store Binary on eMMC (Persistent)

```bash
# Current: Binary runs from /tmp (cleared on reboot)
# Permanent: Store on main storage

# Copy to persistent location
ssh root@$DEVICE_IP "cp /tmp/monitor_service /opt/monitor_service"
ssh root@$DEVICE_IP "chmod +x /opt/monitor_service"

# Update service file to use /opt instead of /tmp
ssh root@$DEVICE_IP "sed -i 's|/tmp/monitor_service|/opt/monitor_service|g' /etc/systemd/system/monitor.service"

# Reload and restart
ssh root@$DEVICE_IP "systemctl daemon-reload && systemctl restart monitor.service"
```

### Automatic Updates (Optional)

```bash
# Create update script
cat > /tmp/update_monitor.sh << 'EOF'
#!/bin/bash
# Update monitoring service binary

cd /Users/roebssie/Desktop/Box_Flasher
cmake --build build-aarch64
scp build-aarch64/monitor_service root@$DEVICE_IP:/opt/monitor_service
ssh root@$DEVICE_IP "systemctl restart monitor.service"
echo "Monitor service updated and restarted"
EOF

chmod +x /tmp/update_monitor.sh

# Run whenever you rebuild
/tmp/update_monitor.sh
```

---

## 🐛 Troubleshooting

### Issue: "Permission denied" when SSHing

**Solution:**
```bash
# Check if SSH is enabled on device
open "http://$DEVICE_IP:8080"
# Settings → System → Services → SSH → Enable

# Or try with explicit options
ssh -o StrictHostKeyChecking=no root@$DEVICE_IP
```

### Issue: "Binary not found" on device

**Solution:**
```bash
# Verify transfer succeeded
ssh root@$DEVICE_IP "ls -la /tmp/ | grep monitor"

# If missing, retransfer
scp build-aarch64/monitor_service root@$DEVICE_IP:/tmp/
```

### Issue: Service fails to start

**Solution:**
```bash
# Check systemd logs
ssh root@$DEVICE_IP "journalctl -u monitor.service -n 100"

# Check if binary is executable
ssh root@$DEVICE_IP "file /opt/monitor_service"

# Manually test
ssh root@$DEVICE_IP "/opt/monitor_service"
```

### Issue: Thermal zone not found

**Solution:**
```bash
# Check available thermal zones on device
ssh root@$DEVICE_IP "ls -la /sys/class/thermal/"

# This is normal - service gracefully handles missing sensors
# CPU temp will show "Unavailable" but RAM/storage always work
```

### Issue: Device reboots and service stops

**Solution:**
```bash
# Ensure service is enabled for auto-start
ssh root@$DEVICE_IP "systemctl is-enabled monitor.service"

# Should output: "enabled"
# If not:
ssh root@$DEVICE_IP "systemctl enable monitor.service"

# Verify after reboot
ssh root@$DEVICE_IP "systemctl status monitor.service"
```

---

## ✅ Verification Checklist

- [ ] SD card flashed with CoreELEC/LibreELEC
- [ ] Device boots and connects to network
- [ ] Device IP identified and noted
- [ ] SSH access working (can login as root)
- [ ] Binary transferred to device
- [ ] Binary runs successfully on device
- [ ] Service created and enabled
- [ ] Service starts on boot (verify after reboot)
- [ ] Logs viewable and rotating properly
- [ ] Monitoring runs persistently

---

## 📊 Complete Setup Command Sequence

```bash
#!/bin/bash
# All-in-one setup (after device is flashed and booted)

export DEVICE_IP="192.168.1.100"  # Change to your device IP

echo "1. Testing SSH connection..."
ssh root@$DEVICE_IP "echo 'SSH OK'"

echo "2. Transferring binary..."
scp build-aarch64/monitor_service root@$DEVICE_IP:/tmp/

echo "3. Testing binary..."
ssh root@$DEVICE_IP "/tmp/monitor_service"

echo "4. Creating systemd service..."
cat > /tmp/monitor.service << 'EOF'
[Unit]
Description=Amlogic S905W System Monitoring Service
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/monitor_service
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

scp /tmp/monitor.service root@$DEVICE_IP:/etc/systemd/system/

echo "5. Installing service..."
ssh root@$DEVICE_IP << 'SSHCMD'
cp /tmp/monitor_service /usr/local/bin/
chmod +x /usr/local/bin/monitor_service
systemctl daemon-reload
systemctl enable monitor.service
systemctl start monitor.service
systemctl status monitor.service
SSHCMD

echo "✅ Setup complete!"
```

Save this script and run:
```bash
bash setup_device.sh
```

---

## 📝 Next Steps

1. **Flash device** with CoreELEC/LibreELEC (Part 1)
2. **Verify device boots** and connects to network
3. **Set up SSH access** (Part 2)
4. **Deploy binary** to device (Part 3)
5. **Create persistent service** using one of three options (Part 4)
6. **Verify service starts on boot** (Part 5)

---

## ❓ Questions?

Check these files:
- `QUICKSTART.md` - Fast deployment reference
- `REPORT.md` - Complete technical documentation
- `src/main.cpp` - Binary source code
- `CMakeToolchain.cmake` - Build configuration for aarch64

For S905W specific issues:
- CoreELEC docs: https://coreelec.org/
- LibreELEC docs: https://libreelec.tv/
