# ⚡ USB-A to USB-A Flashing - Quick Start

## Your Setup

```
┌──────────────┐
│   macBook    │
│ (USB-C port) │
└──────┬───────┘
       │
       │ USB-C to USB-A Adapter
       │ (if needed)
       │
       ↓
    ┌──────────────┐
    │  USB-A Port  │
    │  on macBook  │
    └──────┬───────┘
           │
           │ USB-A to USB-A Cable
           │ (Male to Male)
           │
           ↓
    ┌──────────────┐
    │  USB-A Port  │
    │  on S905W    │
    └──────┬───────┘
           │
           │ (Power separately!)
           ↓
    ┌──────────────────┐
    │  S905W Device    │
    │  (in USB mode)   │
    └──────────────────┘
```

---

## 🚀 Three Steps to Flash

### Step 1️⃣: Prepare (5 minutes)

```bash
# Install tools
brew install libusb libftdi wget

# Create directory
mkdir ~/S905W_USB_Flash && cd ~/S905W_USB_Flash

# Download image (~500MB)
wget https://releases.coreelec.org/CoreELEC-Amlogic.aarch64-latest.img.gz
gunzip CoreELEC-Amlogic.aarch64-latest.img.gz

# Install flashing tool
brew tap messense/amlogic-tools
brew install amlogic-usb-flashing-tool
```

### Step 2️⃣: Connect Device (2 minutes)

```
1. S905W powered OFF
2. Locate boot button on S905W board (or NAND_BOOT jumper)
3. Connect USB-A to USB-A cable:
   - One end: macBook USB port (or via USB-C adapter)
   - Other end: S905W USB-A port
4. While HOLDING boot button:
   - Connect power to S905W
   - Keep holding for 10-15 seconds
   - Release button
5. Device is now in USB flashing mode
```

### Step 3️⃣: Flash (3 minutes)

```bash
cd ~/S905W_USB_Flash

# Verify device detected
system_profiler SPUSBDataType | grep -i amlogic

# Flash the device
aml_usb_flashing_tool \
    --image CoreELEC-Amlogic.aarch64-latest.img \
    --device s905w

# Wait for completion...
# Output should show: ✓ Success
```

---

## ✅ Verification

```bash
# Wait 3 minutes for device to boot

# Find device IP
ping -c 1 coreelec.local

# Test SSH
ssh root@<DEVICE_IP> "uname -a"

# Should see: Linux CoreELEC ...
```

---

## 📱 Cable Type Reference

### ✅ CORRECT: USB-A to USB-A

```
    ┌─────────────┐         ┌─────────────┐
    │  USB-A      │────────│  USB-A      │
    │ (Rectangular)        │ (Rectangular)
    └─────────────┘         └─────────────┘
    macBook                 S905W
```

### ❌ WRONG: USB-A to Micro-USB

```
    ┌─────────────┐         ┌─────┐
    │  USB-A      │────────│Micro│
    │ (Rectangular)        │(Small)
    └─────────────┘         └─────┘
    ✗ Won't work!
```

### ⚠️ ADAPTER: USB-C to USB-A

```
    ┌──────────┐         ┌────────────────┐
    │ USB-C    │────────│ USB-A Adapter  │
    │ on Mac   │         │ to USB-A cable │
    └──────────┘         └────────────────┘
    (Need if macBook has USB-C)
```

---

## 🔍 Troubleshooting Matrix

| Problem | Check | Solution |
|---------|-------|----------|
| Device not detected | `system_profiler SPUSBDataType` | Hold boot button 15+ sec, try different USB port |
| Flashing stalls | Power supply | S905W needs 5V 2A+, try different power |
| Device not on network | Wait 5 min, ping | Device may be booting, check router DHCP |
| SSH connection refused | `ssh root@IP` | Enable SSH: http://IP:8080 → Settings |
| Image corruption | Redownload | Delete and re-download CoreELEC image |

---

## 📋 Checklist Before Flashing

- [ ] USB-A to USB-A cable connected
- [ ] S905W powered OFF
- [ ] Boot button located on board
- [ ] Separate 5V 2A+ power supply ready
- [ ] CoreELEC image downloaded
- [ ] Flashing tool installed
- [ ] Device detected: `system_profiler SPUSBDataType`
- [ ] Ready to flash

---

## ⏱️ Timeline

```
Prepare:        5 min  (install tools, download image)
Device setup:   2 min  (connect USB, boot button)
Flashing:       3-5 min (aml_usb_flashing_tool)
Boot wait:      3 min  (device boots CoreELEC)
Verification:   2 min  (SSH test)
────────────────
TOTAL:         15-20 min
```

---

## 🎯 After Flashing Works

Once device is online and SSH working:

```bash
# Navigate to project
cd /Users/roebssie/Desktop/Box_Flasher

# Export device IP
export DEVICE_IP="192.168.1.XXX"

# Deploy monitoring service (one command!)
./setup_device.sh $DEVICE_IP

# Done! Service now runs persistently on S905W
```

---

## 📞 Quick Command Reference

```bash
# Check if device detected
system_profiler SPUSBDataType | grep -i amlogic

# Flash device
aml_usb_flashing_tool --image CoreELEC-Amlogic.aarch64-latest.img --device s905w

# Find device IP
ping -c 1 coreelec.local

# Test SSH
ssh root@$DEVICE_IP "echo 'Connected!'"

# Deploy service
./setup_device.sh $DEVICE_IP
```

---

## 🚨 Critical Notes

⚠️ **Power:** S905W must have separate power supply (5V 2A+)  
⚠️ **Boot Button:** Hold for 10-15 seconds before releasing  
⚠️ **USB Cable:** Must be USB-A Male to USB-A Male (not Micro-USB)  
⚠️ **Don't Disconnect:** Keep USB connected during entire flashing  
⚠️ **First Boot:** Takes 3 minutes - be patient!  

✅ **Success:** Device appears on network with CoreELEC running

---

## 🔗 Need More Details?

- Full guide: `USB_A_TO_A_FLASHING.md`
- Device setup: `DEVICE_SETUP.md`
- Service deployment: `setup_device.sh`

**Everything is ready to go!** 🚀
