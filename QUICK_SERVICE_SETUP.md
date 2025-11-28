# 🚀 Quick Reference: S905W Persistent Service Setup

## The Complete Flow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. FLASH DEVICE (One-time)                                  │
│    Download image → Flash to SD card → Boot device          │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. DEVICE BOOT & NETWORK (Automatic)                        │
│    Device connects to network → Gets IP address             │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. SETUP PERSISTENT SERVICE (One command!)                  │
│    ./setup_device.sh <DEVICE_IP>                            │
└─────────────────────────────────────────────────────────────┘
```

---

## Step 1️⃣: Flash the Device (30 minutes)

### Quick Commands

```bash
# 1. Download CoreELEC image
cd ~/Downloads
wget https://releases.coreelec.org/CoreELEC-Amlogic.aarch64-latest.img.gz
gunzip CoreELEC-Amlogic.aarch64-latest.img.gz

# 2. Find your SD card
diskutil list
# Look for /dev/diskX (your SD card)
export SD_DEVICE="/dev/disk1"

# 3. Unmount SD card
diskutil unmountDisk $SD_DEVICE

# 4. Flash image (TAKES 2-5 MINUTES)
sudo dd if=~/Downloads/CoreELEC-Amlogic.aarch64-latest.img \
         of=/dev/r${SD_DEVICE#/dev/} \
         bs=4m \
         status=progress

# 5. Eject when done
diskutil eject $SD_DEVICE

# 6. Insert into S905W, power on, wait 2-3 minutes for boot
```

**⚠️ IMPORTANT:** Verify the correct SD card device! Wrong device = data loss!

---

## Step 2️⃣: Find Device IP (2 minutes)

### Methods

```bash
# Method 1: From router admin panel
# Check 192.168.1.1 DHCP table for "CoreELEC"

# Method 2: Using mDNS (if available)
ping -c 1 coreelec.local

# Method 3: Network scan
brew install nmap
nmap -sn 192.168.1.0/24 | grep -i amlogic
```

Once you have the IP:
```bash
export DEVICE_IP="192.168.1.100"  # Replace with actual IP
```

---

## Step 3️⃣: Run ONE Command (5 minutes)

```bash
# From the Box_Flasher directory
cd /Users/roebssie/Desktop/Box_Flasher

# Run the automated setup script
./setup_device.sh $DEVICE_IP

# Example:
./setup_device.sh 192.168.1.100
```

That's it! The script will:
- ✓ Test SSH connection
- ✓ Verify system files exist
- ✓ Transfer binary to device
- ✓ Test binary execution
- ✓ Create systemd service
- ✓ Enable service for auto-boot
- ✓ Start service immediately

---

## What Happens Next

### Service Runs Automatically
- ✅ Runs when device boots
- ✅ Outputs to systemd journal
- ✅ Can be monitored via SSH
- ✅ Restarts on failure (optional)

### Monitor the Service

```bash
# View status
ssh root@$DEVICE_IP "systemctl status monitor.service"

# View live logs (follow mode)
ssh root@$DEVICE_IP "journalctl -u monitor.service -f"

# View recent logs
ssh root@$DEVICE_IP "journalctl -u monitor.service -n 50"

# Run manually
ssh root@$DEVICE_IP "/opt/monitor_service"
```

---

## If Something Goes Wrong

### "SSH connection refused"
```bash
# SSH might not be enabled in CoreELEC web UI
open "http://$DEVICE_IP:8080"
# Go to: Settings → System → Services → SSH → Enable
```

### "Binary not found"
```bash
# Retransfer the binary
scp build-aarch64/monitor_service root@$DEVICE_IP:/tmp/
```

### "Service fails to start"
```bash
# Check systemd logs
ssh root@$DEVICE_IP "journalctl -u monitor.service -n 100"

# Check binary is executable
ssh root@$DEVICE_IP "file /opt/monitor_service"

# Try running manually
ssh root@$DEVICE_IP "/opt/monitor_service"
```

### "Device not booting"
```bash
# Verify SD card properly flashed
diskutil list
# Check if card still shows correct size

# Try flashing again with fresh image
```

---

## Useful Commands Reference

```bash
# Check service status
ssh root@$DEVICE_IP systemctl status monitor.service

# View full logs
ssh root@$DEVICE_IP journalctl -u monitor.service

# Stop service
ssh root@$DEVICE_IP systemctl stop monitor.service

# Restart service
ssh root@$DEVICE_IP systemctl restart monitor.service

# Disable auto-start (manual start only)
ssh root@$DEVICE_IP systemctl disable monitor.service

# Re-enable auto-start
ssh root@$DEVICE_IP systemctl enable monitor.service

# View device system info
ssh root@$DEVICE_IP uname -a

# Check available disk space
ssh root@$DEVICE_IP df -h

# Check running processes
ssh root@$DEVICE_IP ps aux | grep monitor
```

---

## Complete Timeline

| Phase | Duration | What Happens |
|-------|----------|--------------|
| Flash Device | 20 min | Download image, flash SD card |
| Device Boot | 5 min | Device powers on, connects to network |
| Find IP | 2 min | Identify device on network |
| Run Setup | 3 min | Execute setup_device.sh |
| **Total** | **~30 min** | Service running and persistent! |

---

## What Your Service Does

Every time it runs, the service:

1. **Reads CPU Temperature** from `/sys/class/thermal/thermal_zone0/temp`
   - Shows in Celsius
   - Skips gracefully if not available

2. **Reads RAM Usage** from `/proc/meminfo`
   - Total memory
   - Free memory
   - Available memory
   - Used memory with percentage

3. **Lists Storage** from `/proc/mounts`
   - Mounted filesystems (filters /sys, /proc, /dev, etc.)
   - Real storage devices only

4. **Outputs to stdout**
   - When run manually: prints to terminal
   - When run via systemd: logs to journal

---

## Important Notes

✅ **Binary is statically linked** - No dependencies needed on device  
✅ **Single executable** - Just one file to manage  
✅ **Zero configuration** - Runs as-is, no setup files needed  
✅ **Graceful degradation** - Works even if some sensors missing  
✅ **Persistent** - Survives device reboots  
✅ **Logged** - All output captured in systemd journal  

---

## Next Steps After Setup

1. **Verify service works:**
   ```bash
   ssh root@$DEVICE_IP "systemctl status monitor.service"
   ```

2. **Reboot device and verify service restarts:**
   ```bash
   ssh root@$DEVICE_IP "reboot"
   # Wait 2 minutes
   ssh root@$DEVICE_IP "systemctl status monitor.service"
   ```

3. **Monitor regularly:**
   ```bash
   ssh root@$DEVICE_IP "journalctl -u monitor.service -f"
   ```

4. **Update binary (if needed):**
   ```bash
   # Rebuild on macOS
   cmake --build build-aarch64
   
   # Re-run setup script
   ./setup_device.sh 192.168.1.100
   ```

---

## Questions?

See detailed guides:
- `DEVICE_SETUP.md` - Complete step-by-step guide
- `QUICKSTART.md` - Fast reference
- `REPORT.md` - Technical documentation

For S905W specific help:
- CoreELEC: https://coreelec.org/
- LibreELEC: https://libreelec.tv/
