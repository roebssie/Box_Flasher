# 📋 S905W Persistent Service Setup - Complete Summary

## 🎯 What You Need to Do

### Your Current Status: ✅ Binary Built & Ready
```
✓ Binary compiled: build-aarch64/monitor_service (8.6 MB)
✓ Architecture: aarch64 (ARM64) 
✓ Linking: Statically linked
✓ Next: Deploy to S905W device and make it persistent
```

---

## 🔄 The Process (Overview)

```
┌──────────────────────────────────────────────────────────┐
│  PHASE 1: FLASH DEVICE (Do once)                        │
│  ├─ Download CoreELEC/LibreELEC image                   │
│  ├─ Flash to MicroSD card                               │
│  └─ Insert into S905W and power on                       │
└──────────┬───────────────────────────────────────────────┘
           │ Device boots, connects to network
           ↓
┌──────────────────────────────────────────────────────────┐
│  PHASE 2: SETUP SERVICE (Do once)                       │
│  ├─ Find device IP address                              │
│  └─ Run: ./setup_device.sh <IP>                         │
│      (Automatically transfers binary + sets up service)  │
└──────────┬───────────────────────────────────────────────┘
           │ Service created and running
           ↓
┌──────────────────────────────────────────────────────────┐
│  PHASE 3: MONITOR (Ongoing)                             │
│  ├─ Service runs automatically on boot                  │
│  ├─ Monitor via: journalctl -u monitor.service          │
│  └─ Update binary anytime (re-run setup script)         │
└──────────────────────────────────────────────────────────┘
```

---

## 📖 Files You Need to Read

| File | What It Contains | Read If... |
|------|-----------------|-----------|
| `QUICK_SERVICE_SETUP.md` | **Quick reference** | Want fast overview ← START HERE |
| `DEVICE_SETUP.md` | **Detailed step-by-step** | Want complete guide |
| `setup_device.sh` | **Automated setup script** | Want to automate everything |

---

## ⚡ TL;DR - Super Quick Version

### 1. Flash Device (first time only)
```bash
# Download and flash CoreELEC image to MicroSD
# Insert card, power on S905W
# Wait for device to boot
```

### 2. Find Device IP
```bash
# Check your router or use:
ping coreelec.local
```

### 3. Run This One Command
```bash
cd /Users/roebssie/Desktop/Box_Flasher
./setup_device.sh 192.168.1.100  # Replace with your device IP
```

**Done!** Service is now persistent and runs on every boot.

---

## 📋 Step-by-Step Instructions

### STEP 1: Download & Flash OS Image (30 minutes, first time only)

**Option A: CoreELEC (Recommended)**
```bash
# Download
cd ~/Downloads
wget https://releases.coreelec.org/CoreELEC-Amlogic.aarch64-latest.img.gz
gunzip CoreELEC-Amlogic.aarch64-latest.img.gz

# Flash to SD card
diskutil list                              # Find your SD card (e.g., /dev/disk1)
diskutil unmountDisk /dev/disk1            # Unmount
sudo dd if=CoreELEC-Amlogic.aarch64-latest.img \
        of=/dev/rdisk1 bs=4m status=progress
diskutil eject /dev/disk1                  # Eject when done
```

**Option B: LibreELEC**
```bash
cd ~/Downloads
wget https://releases.libreelec.tv/LibreELEC-Amlogic.aarch64-latest.img.gz
gunzip LibreELEC-Amlogic.aarch64-latest.img.gz
# Same flashing steps as CoreELEC above
```

**Action:** Insert SD card into S905W, power on, wait 3 minutes

---

### STEP 2: Find Device IP Address (2 minutes)

```bash
# Method 1: Check router admin panel (192.168.1.1)
# Look for "CoreELEC" or "LibreELEC" in DHCP clients

# Method 2: Use mDNS
ping -c 1 coreelec.local

# Method 3: Network scan
brew install nmap
nmap -sn 192.168.1.0/24 | grep -i amlogic

# Export the IP
export DEVICE_IP="192.168.1.100"  # Replace with your actual IP
```

---

### STEP 3: Run Automated Setup (5 minutes)

```bash
# Navigate to project
cd /Users/roebssie/Desktop/Box_Flasher

# Run setup script
./setup_device.sh $DEVICE_IP

# It will automatically:
# 1. Test SSH connection
# 2. Transfer binary
# 3. Test binary on device
# 4. Create systemd service
# 5. Enable for auto-boot
# 6. Start immediately
```

**That's it! 🎉 Service is now persistent!**

---

## ✅ Verification

### Check Service Status
```bash
ssh root@$DEVICE_IP "systemctl status monitor.service"

# Expected output:
# ● monitor.service - Amlogic S905W System Monitoring Service
#    Loaded: loaded (/etc/systemd/system/monitor.service; enabled; vendor preset: enabled)
#    Active: active (exited) since Thu 2025-11-27 20:30:00 UTC
```

### View Service Logs
```bash
# Live logs (follow mode - Ctrl+C to stop)
ssh root@$DEVICE_IP "journalctl -u monitor.service -f"

# Recent logs
ssh root@$DEVICE_IP "journalctl -u monitor.service -n 20"
```

### Run Service Manually
```bash
ssh root@$DEVICE_IP "/opt/monitor_service"

# Should show:
# === System Monitoring Service ===
# Target: Amlogic S905W Embedded Linux
# 
# CPU Temperature:
#   Temperature: XX.XX °C (or "Unavailable")
# 
# RAM Usage:
#   Total:     XXX.XX MB
#   Free:      XXX.XX MB
#   Available: XXX.XX MB
#   Used:      XXX.XX MB (XX%)
# 
# Storage Information:
# Mounted filesystems (storage points):
#   - /
#   - /boot
#   - /media
```

---

## 🔧 Management Commands

### Control the Service
```bash
# Start service
ssh root@$DEVICE_IP "systemctl start monitor.service"

# Stop service
ssh root@$DEVICE_IP "systemctl stop monitor.service"

# Restart service
ssh root@$DEVICE_IP "systemctl restart monitor.service"

# Disable auto-start (manual start only)
ssh root@$DEVICE_IP "systemctl disable monitor.service"

# Re-enable auto-start
ssh root@$DEVICE_IP "systemctl enable monitor.service"
```

### View Logs with Different Filters
```bash
# Last 100 lines
ssh root@$DEVICE_IP "journalctl -u monitor.service -n 100"

# Since last boot
ssh root@$DEVICE_IP "journalctl -u monitor.service --since today"

# With timestamps
ssh root@$DEVICE_IP "journalctl -u monitor.service --since '10 minutes ago' -o short-precise"

# Show only errors
ssh root@$DEVICE_IP "journalctl -u monitor.service --priority err"
```

---

## 🔄 Update Binary (When You Rebuild)

### Quick Update
```bash
# 1. Rebuild on macOS
cd /Users/roebssie/Desktop/Box_Flasher
cmake --build build-aarch64

# 2. Re-run setup (updates binary and restarts service)
./setup_device.sh 192.168.1.100

# 3. Verify
ssh root@$DEVICE_IP "systemctl status monitor.service"
```

---

## 🐛 Troubleshooting

### Problem: "SSH: Permission denied"
```bash
# SSH not enabled in CoreELEC/LibreELEC
# Solution: Open web UI and enable SSH
open "http://192.168.1.100:8080"
# Settings → System → Services → SSH → Enable
```

### Problem: "Connection refused"
```bash
# Wrong IP or device not booted
# Verify IP:
ping -c 1 coreelec.local

# Or check router DHCP table for CoreELEC
```

### Problem: "Binary not found after transfer"
```bash
# Retransfer binary
scp build-aarch64/monitor_service root@$DEVICE_IP:/tmp/
```

### Problem: "Service fails to start"
```bash
# Check detailed logs
ssh root@$DEVICE_IP "journalctl -u monitor.service -n 50"

# Verify binary is executable
ssh root@$DEVICE_IP "file /opt/monitor_service"

# Try running manually
ssh root@$DEVICE_IP "/opt/monitor_service"
```

### Problem: "CPU Temperature shows Unavailable"
```bash
# This is normal! Not all devices have thermal zone exposed
# Check if it exists:
ssh root@$DEVICE_IP "ls /sys/class/thermal/"

# If empty, CPU temp just won't be available
# RAM and storage info will always work
```

---

## 📊 What Happens After Setup

### On Device Boot
```
1. Device boots CoreELEC/LibreELEC
2. Systemd starts monitor.service
3. Binary runs: /opt/monitor_service
4. Output logged to systemd journal
5. Service completes
```

### View Persistent Output
```bash
# Service runs automatically, output in journal
ssh root@$DEVICE_IP "journalctl -u monitor.service -f"

# Or check logs anytime
ssh root@$DEVICE_IP "journalctl -u monitor.service"
```

### Optional: Scheduled Running
If you want to run periodically instead of once at boot:

```bash
# Edit systemd timer (advanced)
ssh root@$DEVICE_IP "systemctl edit --full monitor.timer"

# Or use cron (simpler)
ssh root@$DEVICE_IP "crontab -e"
# Add: */5 * * * * /opt/monitor_service >> /var/log/monitor.log 2>&1
```

---

## 🎯 What You've Accomplished

✅ Built aarch64 binary on macOS  
✅ Cross-compiled to S905W architecture  
✅ Verified deployment compatibility  
✅ Created automated setup script  
✅ Documented everything  

**Next:** Deploy to device and run persistent service!

---

## 📞 Need Help?

### Quick Issues
- Binary won't run? → Check `DEVICE_SETUP.md` Troubleshooting section
- Flashing device issues? → See CoreELEC/LibreELEC docs
- SSH not connecting? → Enable SSH in CoreELEC web UI

### Detailed Docs
- `DEVICE_SETUP.md` - Complete guide with all options
- `QUICK_SERVICE_SETUP.md` - Quick reference
- `REPORT.md` - Technical architecture
- `src/main.cpp` - Source code

### External Resources
- CoreELEC: https://coreelec.org/
- LibreELEC: https://libreelec.tv/
- Amlogic S905W docs

---

## 🚀 Ready to Deploy?

1. **Flash device** → Follow STEP 1
2. **Find IP** → Follow STEP 2
3. **Run setup** → Follow STEP 3
4. **Done!** → Service is persistent

**Estimated time:** ~35 minutes total (including device flash)

```bash
./setup_device.sh 192.168.1.100
```

Let me know when you're ready! 🎉
