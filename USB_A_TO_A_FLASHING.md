# 🔌 Amlogic S905W USB-A to USB-A Direct Flashing (macOS)

## Overview

This guide covers flashing an Amlogic S905W device using a **USB-A to USB-A cable** connection directly to your macBook.

---

## ⚠️ Important: USB-A to USB-A Connection

### Setup Configuration
```
macBook (USB-A port on adapter)
    ↓
USB-A to USB-A Cable
    ↓
S905W Device (USB-A port)
```

### Requirements
- **Cable:** USB-A Male to USB-A Male cable (or USB-A Male to USB-A Female adapter with USB-A cable)
- **Adapter (if needed):** USB-C to USB-A adapter for modern macBooks
- **S905W Device:** Must have USB-A port exposed and support USB flashing mode
- **Power:** S905W must be powered separately (5V 2A+)

---

## Part 1: Prerequisites & Setup

### Hardware Checklist

```
✓ macBook with USB-C ports (modern) or USB-A ports (older)
✓ USB-A to USB-A cable (OR USB-A Female to USB-A Male cable)
✓ USB-C to USB-A adapter (if macBook has USB-C only)
✓ Amlogic S905W with USB-A port
✓ Power supply for S905W (5V 2A minimum)
✓ Network cable (for post-flash setup, optional)
```

### Verify USB Cable Type

```bash
# Your cable should be:
# USB-A (rectangular, flat end) ---- USB-A (rectangular, flat end)
#    ↑                                    ↑
#   macBook                          S905W Device
```

**Common Issues:**
- ❌ USB-A to Micro-USB (wrong - won't fit)
- ❌ USB-C to USB-A (only works with adapter)
- ✅ USB-A to USB-A (correct)

---

## Part 2: Software Installation (macOS)

### Step 2.1: Install Required Tools

```bash
# Install Homebrew if needed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install USB flashing tools
brew install libusb libftdi wget

# Verify installation
brew list | grep -E "libusb|libftdi"
```

# Step 2.2: Download Flashing Tools

```bash
# Create working directory
mkdir -p ./S905W_USB_Flash
cd /S905W_USB_Flash

# NOTE: The CoreELEC site does not provide a fixed "CoreELEC-Amlogic.aarch64-latest.img.gz" filename.
# Use one of the current Amlogic images from the CoreELEC releases. Two safe options:

# Option A - Download directly from the CoreELEC releases index (recommended):
# 1. Open https://releases.coreelec.org/releases.json and find the latest Amlogic aarch64 entry
# 2. The releases point to GitHub release assets. Example (change version if newer):
wget https://github.com/CoreELEC/CoreELEC/releases/download/21.3-Omega/CoreELEC-Amlogic-ne.aarch64-21.3-Omega.tar

# Option B - If you prefer a compressed image and a single-file workflow, pick the matching .img.gz from the release assets
# Example (replace with the exact name you find in releases.json or on the CoreELEC releases page):
# wget https://releases.coreelec.org/21.3-Omega/CoreELEC-Amlogic-ne.aarch64-21.3-Omega.img.gz

# After download, verify checksum (if available) and extract. Example for a tar archive:
sha256sum CoreELEC-Amlogic-ne.aarch64-21.3-Omega.tar  # compare with release checksum
tar -xvf CoreELEC-Amlogic-ne.aarch64-21.3-Omega.tar

# Or for a gzipped image:
gunzip CoreELEC-Amlogic-ne.aarch64-21.3-Omega.img.gz

# Verify extracted image file size roughly matches the release notes (~200-300MB+ depending on build)
ls -lh CoreELEC-*
```

### Step 2.3: Install Amlogic USB Flashing Tool

```bash
# Try method 1: Homebrew tap
brew tap messense/amlogic-tools
brew install amlogic-usb-flashing-tool

# If that doesn't work, method 2: Download from GitHub
cd ~/S905W_USB_Flash
wget https://github.com/khadas/fenix/releases/download/v1.0/aml_usb_flashing_tool-macOS.zip
unzip aml_usb_flashing_tool-macOS.zip
chmod +x aml_usb_flashing_tool

# Test if tool is available
aml_usb_flashing_tool --version || ./aml_usb_flashing_tool --version
```

---

## Part 3: Prepare S905W for USB Flashing

### Step 3.1: Enter USB Flashing Mode

**CRITICAL:** Device must be in "USB Flashing Mode" (also called "Maskrom Mode" or "Download Mode")

#### Method 1: Boot Button (If S905W has one)

```
1. Power OFF the S905W device completely
2. Disconnect all cables except USB
3. Locate the small boot/recovery button on the S905W board
   (Usually near USB port or labeled BOOT)
4. Connect USB-A to USB-A cable:
   - One end to macBook (or via USB-C adapter)
   - Other end to S905W USB-A port
5. While HOLDING the boot button:
   a. Connect power supply to S905W
   b. Hold button for 10-15 seconds
   c. Device LEDs may flash
6. Release boot button
7. Device is now in USB flashing mode

Visual:
┌─────────────────────────────────────────────┐
│  S905W Board (top view)                     │
│                                             │
│  ┌─────────────┐                           │
│  │   USB-A ────────→ (to macBook)          │
│  └─────────────┘                           │
│                                             │
│  [BOOT btn] ← HOLD THIS                    │
│                                             │
│  [Power Jack] ← CONNECT POWER              │
│                                             │
└─────────────────────────────────────────────┘
```

#### Method 2: Jumper Pin (If no button)

```
1. Power OFF completely
2. Disconnect all cables
3. Locate NAND_BOOT jumper pins on board
   (Usually marked J1, J2, or similar)
4. Move jumper to NAND_BOOT position (or short pins)
5. Connect USB cable
6. Connect power supply
7. Device enters flashing mode
8. After flashing: restore jumper to normal position
```

#### Method 3: Software Method (If already running old OS)

```bash
# SSH into device (if accessible)
ssh root@<DEVICE_IP>

# Enter flashing mode via command
reboot maskrom

# Device reboots into flashing mode
```

---

## Part 4: Detect Device on macOS

### Step 4.1: Verify USB Connection

```bash
# Check if Amlogic device is detected
system_profiler SPUSBDataType | grep -i amlogic

# Or check for vendor ID 1b8e (Amlogic)
system_profiler SPUSBDataType | grep -i "1b8e"

# Expected output should show:
# Amlogic Device / Vendor ID: 0x1b8e
```

### Step 4.2: List All USB Devices

```bash
# Show all USB devices
system_profiler SPUSBDataType

# Look for your S905W device (usually shows as Amlogic or unknown device)
# Note the Bus Power and other identifying info
```

### Step 4.3: Troubleshooting Detection

If device NOT detected:

```bash
# 1. Verify cable is connected
ls -la /dev/tty.usb* 2>/dev/null || echo "No USB serial devices found"

# 2. Check with ioreg (Mac I/O registry)
ioreg -p IOUSB -l -w 0 | grep -A 5 -B 5 "1b8e"

# 3. Force USB reset (if available)
sudo dmesg | tail -20  # Check kernel logs

# 4. Try different USB port on macBook
# 5. Try different USB cable
# 6. Verify S905W boot button was held long enough (10-15 seconds)
```

---

## Part 5: Flash Using USB-A Connection

### Step 5.1: Direct Flashing with USB-A Cable

```bash
cd ~/S905W_USB_Flash

# Method 1: Using Amlogic USB Flashing Tool (recommended)
aml_usb_flashing_tool \
    --image CoreELEC-Amlogic.aarch64-latest.img \
    --device s905w

# If that doesn't work, try:
./aml_usb_flashing_tool \
    --image CoreELEC-Amlogic.aarch64-latest.img \
    --device s905w
```

### Step 5.2: Manual USB Flashing (If tool fails)

```bash
cd ~/S905W_USB_Flash

# Identify the USB device
diskutil list external | grep "^/dev"

# Example output:
# /dev/disk3 (external, physical):
#    #:                     TYPE NAME          SIZE
#    0:      FDisk_partition_scheme            *7.9 GB     disk3

# Set your device (VERIFY THIS IS CORRECT!)
export USB_DEVICE="/dev/disk3"

# CAUTION: Triple-check you have the right device!
diskutil info "$USB_DEVICE"

# Unmount the device
diskutil unmountDisk "$USB_DEVICE"

# Flash with dd (takes 2-5 minutes)
echo "⚠️  DO NOT DISCONNECT USB CABLE!"
echo "Flashing in progress..."
echo ""

sudo dd if=CoreELEC-Amlogic.aarch64-latest.img \
        of="/dev/r${USB_DEVICE#/dev/}" \
        bs=4m \
        status=progress

# Wait for completion
sync

echo ""
echo "✓ Flashing complete!"

# Eject device
diskutil eject "$USB_DEVICE"
```

### Step 5.3: Monitor Flashing Progress

```bash
# In another terminal, watch the process
watch -n 1 'diskutil list | grep -A 5 "/dev/disk3"'

# Or check I/O stats
iostat -w 1

# Stop watching with Ctrl+C
```

---

## Part 6: Post-Flashing Setup

### Step 6.1: After Flashing Complete

```bash
echo "1. Disconnect USB-A cable from S905W"
echo "2. Keep power connected to S905W"
echo "3. Wait 3 minutes for device to boot into CoreELEC"
echo "4. Device LEDs should indicate activity"
```

### Step 6.2: Verify Device Booted

```bash
# Wait 3 minutes, then check if device is on network

# Method 1: mDNS
ping -c 1 coreelec.local

# Method 2: Manual IP scan
nmap -sn 192.168.1.0/24 | grep -i "amlogic\|coreelec"

# Method 3: Check router DHCP clients
# Open http://192.168.1.1 (router admin)
# Look for "CoreELEC" in DHCP table

# Export the IP for next steps
export DEVICE_IP="192.168.1.XXX"  # Replace with actual IP
```

### Step 6.3: Test SSH Connection

```bash
# Test SSH access to device
ssh root@$DEVICE_IP "uname -a"

# If prompted for password, try:
# (blank/empty)
# "openelec"
# "root"

# If connection successful, you'll see device info:
# Linux CoreELEC 5.x.x ...
```

---

## Part 7: Deploy Monitoring Service

### Once Device is Online

```bash
# Navigate to monitoring service project
cd /Users/roebssie/Desktop/Box_Flasher

# Run setup script with device IP
./setup_device.sh $DEVICE_IP

# This will:
# 1. Transfer binary to device
# 2. Create systemd service
# 3. Enable auto-boot
# 4. Start service immediately
```

---

## 🐛 Troubleshooting USB-A Connection

### Problem: "Amlogic device not detected"

**Checklist:**
```bash
# 1. Verify USB cable is connected
# 2. Check cable is USB-A to USB-A (not Micro-USB)
# 3. Try different USB port on macBook
# 4. Try different USB-A to USB-A cable
# 5. Verify adapter is working (if using USB-C adapter)

# Test adapter:
system_profiler SPUSBDataType | grep -i "hub\|adapter"
```

**Solution:**
```bash
# Try with verbose output
aml_usb_flashing_tool \
    --image CoreELEC-Amlogic.aarch64-latest.img \
    --device s905w \
    --verbose

# If still not detected, check kernel logs
sudo dmesg | tail -50 | grep -i "usb\|amlogic"
```

### Problem: "Boot button didn't work"

**Solution:**
```
1. Power OFF again
2. Hold boot button for LONGER (15-20 seconds)
3. Look for LED blinking/activity
4. Try different boot button area
5. Use jumper method instead (Step 3.2)
```

### Problem: "Flashing stops halfway"

**Solution:**
```bash
# USB power might be insufficient
# Check power supply to S905W:
ssh root@$DEVICE_IP "cat /sys/class/power_supply/*/uevent | grep VOLTAGE"

# Verify S905W has 5V 2A+ power
# Try flashing again
# Check USB cable integrity
```

### Problem: "Device not appear on network after flashing"

**Solution:**
```bash
# Wait longer (5 minutes)
# Check if device is running:
#   - Look for LED activity
#   - Device might be in boot loop

# Try manual SSH every 10 seconds:
watch -n 10 "ssh -o ConnectTimeout=2 root@192.168.1.100 'echo OK' 2>&1 || true"

# If device keeps rebooting, image might be corrupted
# Re-download and flash again
```

### Problem: "Permission denied" when running dd

**Solution:**
```bash
# The dd command requires sudo
# Make sure to run with sudo:
sudo dd if=CoreELEC-Amlogic.aarch64-latest.img \
        of=/dev/rdisk3 \
        bs=4m \
        status=progress
```

### Problem: "USB cable not being recognized"

**Solution:**
```bash
# Test cable with different device first
# Verify it's data cable (not just power)
# Try reversing USB-A connectors (both sides are same)
# Check if cable needs to be in specific USB port

# If using adapter, test adapter:
system_profiler SPUSBDataType
# Should show your adapter in the list
```

---

## ✅ Complete Quick Reference

### One-Command Setup (after prerequisites installed)

```bash
#!/bin/bash

# Complete USB-A flashing sequence

cd ~/S905W_USB_Flash

# 1. Download image if not present
if [ ! -f CoreELEC-Amlogic.aarch64-latest.img ]; then
    wget https://releases.coreelec.org/CoreELEC-Amlogic.aarch64-latest.img.gz
    gunzip CoreELEC-Amlogic.aarch64-latest.img.gz
fi

# 2. Check device is detected
echo "Checking for Amlogic device..."
system_profiler SPUSBDataType | grep -i amlogic || {
    echo "⚠️  Device not detected!"
    echo "Make sure S905W is connected via USB-A cable"
    echo "and is in USB flashing mode (boot button held)"
    exit 1
}

# 3. Flash device
echo "Starting USB flashing..."
aml_usb_flashing_tool \
    --image CoreELEC-Amlogic.aarch64-latest.img \
    --device s905w

# 4. Post-flash instructions
echo ""
echo "✓ Flashing complete!"
echo ""
echo "Next steps:"
echo "1. Disconnect USB-A cable"
echo "2. Keep power connected"
echo "3. Wait 3 minutes"
echo "4. Find device IP: ping -c 1 coreelec.local"
echo "5. Deploy service: ./setup_device.sh <IP>"
```

---

## 📋 USB-A Connection Checklist

- [ ] USB-A to USB-A cable available (or adapter)
- [ ] macBook with USB ports (or USB-C adapter)
- [ ] S905W has USB-A port exposed
- [ ] Homebrew installed on macBook
- [ ] libusb and libftdi installed: `brew install libusb libftdi`
- [ ] CoreELEC image downloaded (~500MB)
- [ ] Amlogic USB flashing tool installed
- [ ] S905W powered OFF before starting
- [ ] Boot button located (or jumper identified)
- [ ] USB cable connected to both devices
- [ ] Device in flashing mode (boot button held 10-15 seconds)
- [ ] Device detected by macOS
- [ ] Flashing tool starts successfully
- [ ] Device reboots after flashing
- [ ] Device appears on network after 3 minutes
- [ ] SSH access working to device

---

## 🔗 Resources

### Download Locations
- CoreELEC: https://coreelec.org/download/
- LibreELEC: https://libreelec.tv/download/
- Amlogic Tools: https://github.com/khadas/fenix/releases

### USB-A Cable Resources
- Amazon: Search "USB-A to USB-A Male" or "USB-A Male Coupler"
- Local electronics store
- Note: Less common than Micro-USB, may need to order

### Troubleshooting
- CoreELEC Forum: https://github.com/CoreELEC/CoreELEC/issues
- S905W Documentation: Amlogic datasheet for your specific variant

---

## ⏱️ Time Estimate

| Task | Duration |
|------|----------|
| Install tools (first time) | 10 minutes |
| Download CoreELEC image | 10-15 minutes |
| Prepare device/boot button | 2 minutes |
| USB flashing process | 3-5 minutes |
| Device boot and network | 3 minutes |
| SSH verification | 1 minute |
| **TOTAL** | **~30-35 minutes** |

---

## 🎯 Success Indicators

✅ **Flashing successful if:**
- Tool shows "Flashing..." → Progress → "Complete"
- No error messages
- Device reboots automatically
- CoreELEC appears on network within 3 minutes
- SSH access works: `ssh root@$DEVICE_IP`

❌ **If flashing fails:**
- Tool shows error or hangs
- Device doesn't reboot
- Device not on network after 5 minutes
- SSH connection refused

---

## 💡 Tips

1. **Use high-quality USB-A to USB-A cable** - Cheap cables may have connection issues
2. **Ensure good power supply** - S905W needs 5V 2A+ during flashing
3. **Keep boot button held for full 15 seconds** - Don't release early
4. **Try different USB port** on macBook if not detected
5. **Disable USB selective suspend** if having disconnection issues
6. **Have a terminal window open** to monitor progress
7. **Don't power off** during flashing - wait for completion

---

## Next Steps After Flashing

Once CoreELEC is running on your S905W:

```bash
# 1. Find device IP
ping -c 1 coreelec.local
# or
export DEVICE_IP="192.168.1.XXX"

# 2. Deploy monitoring service
cd /Users/roebssie/Desktop/Box_Flasher
./setup_device.sh $DEVICE_IP

# 3. Verify service is running
ssh root@$DEVICE_IP "systemctl status monitor.service"

# 4. View logs
ssh root@$DEVICE_IP "journalctl -u monitor.service -f"
```

---

**You're all set! Your S905W will now run the monitoring service persistently.** 🚀
