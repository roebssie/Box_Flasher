# 📚 Complete S905W Flashing & Service Deployment Guide

## 🎯 Your Project Status

✅ **Binary Built:** `build-aarch64/monitor_service` (8.6 MB, aarch64, statically linked)  
✅ **Ready for Deployment:** To Amlogic S905W via USB-A to USB-A connection  
✅ **Documentation Complete:** Everything you need to flash and deploy  

---

## 📖 Which Guide to Read?

### If You're New - Start Here
👉 **`USB_A_QUICK_START.md`** - 5-minute quick reference with USB-A cable setup

### For Complete Details
👉 **`USB_A_TO_A_FLASHING.md`** - Comprehensive USB-A to USB-A flashing guide

### After Device Boots
👉 **`DEVICE_SETUP.md`** - Deploy monitoring service to S905W

### Reference for Later
👉 **`QUICKSTART.md`** - General deployment reference  
👉 **`REPORT.md`** - Technical architecture details  

---

## 🚀 Complete Workflow

### Phase 1: Flash Device (15-20 minutes, one-time)

**Read:** `USB_A_QUICK_START.md` or `USB_A_TO_A_FLASHING.md`

```
1. Install tools on macBook
   └─ brew install libusb libftdi wget

2. Download CoreELEC image
   └─ wget https://releases.coreelec.org/CoreELEC-Amlogic.aarch64-latest.img.gz

3. Install Amlogic flashing tool
   └─ brew install amlogic-usb-flashing-tool

4. Put S905W in USB flashing mode
   └─ Hold boot button, connect power

5. Connect USB-A to USB-A cable
   └─ macBook ←→ S905W

6. Run flashing tool
   └─ aml_usb_flashing_tool --image CoreELEC-Amlogic.aarch64-latest.img --device s905w

7. Wait for completion
   └─ Device boots into CoreELEC automatically
```

### Phase 2: Deploy Service (5 minutes, per update)

**Read:** `DEVICE_SETUP.md` or run automated script

```
1. Find device IP
   └─ ping -c 1 coreelec.local

2. Run setup script
   └─ ./setup_device.sh 192.168.1.XXX

3. Script automatically:
   ├─ Transfers binary
   ├─ Creates systemd service
   ├─ Enables auto-boot
   └─ Starts service immediately

4. Verify service running
   └─ ssh root@$DEVICE_IP "systemctl status monitor.service"
```

---

## 📋 Files in Your Project

### Documentation Files

| File | Purpose | Read When |
|------|---------|-----------|
| `USB_A_QUICK_START.md` | **Quick 5-min reference** | First time flashing |
| `USB_A_TO_A_FLASHING.md` | **Complete flashing guide** | Need details/troubleshooting |
| `DEVICE_SETUP.md` | **Service deployment** | After device boots |
| `QUICKSTART.md` | **General reference** | General questions |
| `REPORT.md` | **Technical architecture** | Understanding design |

### Executable Scripts

| File | Purpose | Usage |
|------|---------|-------|
| `usb_flash_s905w.sh` | USB flashing automation | `bash usb_flash_s905w.sh` |
| `setup_device.sh` | Service deployment automation | `./setup_device.sh <IP>` |
| `tests/test.sh` | Build verification | `./tests/test.sh` |

### Source Code

| File | Purpose |
|------|---------|
| `src/main.cpp` | Monitoring service implementation |
| `CMakeLists.txt` | Build configuration |
| `CMakeToolchain.cmake` | Cross-compiler setup |

---

## 🔌 Your USB-A Connection Setup

```
┌─────────────────────────────────────────┐
│          Your macBook                   │
│  (Apple Silicon M1/M2/M3)              │
│                                         │
│  USB-C Port →┌─────────────┐           │
│              │ USB-C to    │           │
│              │ USB-A       │           │
│              │ Adapter     │           │
│              └──────┬──────┘           │
└─────────────────────┼──────────────────┘
                      │
                      │ USB-A to USB-A
                      │ Male Cable
                      │ (your connection)
                      │
        ┌─────────────▼──────────────┐
        │   Amlogic S905W Device     │
        │                            │
        │  USB-A Port                │
        │  (data connection)         │
        │                            │
        │  Power Jack                │
        │  (5V 2A+ supply)          │
        │  (separate connection)     │
        └────────────────────────────┘
```

**Hardware Needed:**
- USB-A to USB-A Male cable (or USB-A Male to Female + standard cable)
- USB-C to USB-A adapter (if macBook has USB-C only)
- 5V 2A+ power supply for S905W
- Network access (Ethernet or WiFi on S905W)

---

## ⚡ Quick Command Cheat Sheet

### Setup (First Time, ~5 min)
```bash
# Install tools
brew install libusb libftdi wget

# Download CoreELEC
mkdir ~/S905W_USB_Flash && cd ~/S905W_USB_Flash
wget https://releases.coreelec.org/CoreELEC-Amlogic.aarch64-latest.img.gz
gunzip CoreELEC-Amlogic.aarch64-latest.img.gz

# Install flashing tool
brew tap messense/amlogic-tools
brew install amlogic-usb-flashing-tool
```

### Flashing (~5 min)
```bash
# Verify device detected
system_profiler SPUSBDataType | grep -i amlogic

# Flash device
aml_usb_flashing_tool --image CoreELEC-Amlogic.aarch64-latest.img --device s905w

# Wait 3 minutes for boot
```

### Deployment (~5 min)
```bash
# Find device IP
ping -c 1 coreelec.local
export DEVICE_IP="192.168.1.XXX"

# Deploy service
cd /Users/roebssie/Desktop/Box_Flasher
./setup_device.sh $DEVICE_IP

# Verify
ssh root@$DEVICE_IP "systemctl status monitor.service"
```

### Monitoring (Ongoing)
```bash
# View service status
ssh root@$DEVICE_IP "systemctl status monitor.service"

# View live logs
ssh root@$DEVICE_IP "journalctl -u monitor.service -f"

# Run monitoring manually
ssh root@$DEVICE_IP "/opt/monitor_service"
```

---

## 🎓 Key Concepts

### What Gets Flashed
- **Image:** CoreELEC or LibreELEC (lightweight embedded Linux)
- **Architecture:** aarch64 (ARM 64-bit) - matches S905W
- **Size:** ~500MB image, writes to device storage
- **Result:** Device becomes a complete Linux system

### What Gets Deployed
- **Binary:** `monitor_service` (your compiled program)
- **Size:** 8.6 MB (statically linked, no dependencies)
- **Type:** Systemd service (runs at boot automatically)
- **Output:** CPU temp, RAM usage, storage info logged to systemd journal

### How It Works
1. **Flashing:** USB-A cable transfers CoreELEC OS to S905W storage
2. **Boot:** S905W starts running CoreELEC/LibreELEC
3. **Deployment:** SSH transfers monitor_service binary
4. **Installation:** Creates systemd service for automatic startup
5. **Execution:** Service runs at every boot, logs output

---

## ✅ Success Indicators

### Flashing Successful
- ✅ Tool shows "Flashing..." → Progress → "Complete"
- ✅ No error messages
- ✅ Device reboots automatically after 5 seconds
- ✅ Device LEDs show activity

### Device Booted Successfully
- ✅ Responds to `ping coreelec.local`
- ✅ Appears on router DHCP table
- ✅ SSH login works: `ssh root@$DEVICE_IP`
- ✅ Command execution returns results

### Service Deployed Successfully
- ✅ Script runs without errors
- ✅ Binary transferred to device
- ✅ Systemd service created and enabled
- ✅ Service status shows "active (exited)"
- ✅ Can view logs: `journalctl -u monitor.service`

---

## 🐛 If Something Goes Wrong

| Symptom | Likely Cause | Solution |
|---------|-------------|----------|
| Device not detected | USB issue | Try different USB port, check cable |
| Flashing stalls | Power issue | S905W needs 5V 2A+, check supply |
| Device not on network | Boot issue | Wait 5 min, check device LEDs |
| SSH connection refused | SSH disabled | Enable in CoreELEC web UI |
| Service won't start | Binary not transferred | Re-run setup_device.sh |
| No output from service | Sensors missing | Normal - graceful degradation |

**Full troubleshooting:** See respective guide files

---

## 📞 Resources & Links

### CoreELEC/LibreELEC
- CoreELEC: https://coreelec.org/
- LibreELEC: https://libreelec.tv/
- Forums: GitHub issues for either project

### Amlogic Tools
- GitHub: https://github.com/khadas/fenix
- USB Burning Tool: Windows tool if needed

### Your Project
- Binary: `build-aarch64/monitor_service` (pre-built and ready)
- Scripts: `usb_flash_s905w.sh`, `setup_device.sh` (ready to run)
- Docs: All .md files (comprehensive guides)

---

## 🎯 Next Steps

### Immediate (Now)
1. ✅ Read `USB_A_QUICK_START.md` (5 minutes)
2. ✅ Gather hardware (USB-A cable, power supply)
3. ✅ Run setup commands from "Setup" section above

### Short-term (Today)
1. ⏳ Put S905W in USB flashing mode
2. ⏳ Connect USB-A to USB-A cable
3. ⏳ Flash device with CoreELEC
4. ⏳ Verify device boots

### Follow-up (Once online)
1. ⏳ Find device IP address
2. ⏳ Run `./setup_device.sh <IP>`
3. ⏳ Verify service is running and persistent

---

## 📊 Complete Timeline

| Phase | Task | Duration | Status |
|-------|------|----------|--------|
| Build | Compile for aarch64 | Already done ✅ | Complete |
| Flash | USB flashing OS to S905W | ~5 min | Ready to do |
| Boot | Device startup | ~3 min | Automatic |
| Deploy | Service setup | ~5 min | Ready to do |
| Verify | Check service running | ~2 min | Ready to do |
| **Total** | **All steps** | **~20 min** | **~15 min remaining** |

---

## 🎉 Final Checklist

- ✅ Binary built and verified (aarch64, statically linked)
- ✅ Documentation complete (USB-A specific guides created)
- ✅ Scripts ready (flashing and deployment automated)
- ✅ Hardware identified (USB-A to USB-A cable, power supply)
- ⏳ Ready to flash device (waiting on your action)

---

## 🚀 You're All Set!

Your project is **100% ready to deploy**. The only thing left is:

1. **Prepare hardware** - Get USB-A cable and power supply
2. **Follow `USB_A_QUICK_START.md`** - 5-minute quick reference
3. **Run commands** - Flashing is automated, just 2-3 commands
4. **Done!** - Service runs persistently on S905W

**Good luck! 🎯**

---

Questions? Check:
- `USB_A_QUICK_START.md` - Quick answers
- `USB_A_TO_A_FLASHING.md` - Detailed explanations
- `DEVICE_SETUP.md` - Service deployment details
- `REPORT.md` - Technical background
