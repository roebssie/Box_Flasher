# ✅ Data Organization Complete

Your project now has a **centralized data management system**. All application data, images, configurations, and resources are organized within the codebase.

---

## 📊 What Was Created

### Directory Structure
```
data/
├── images/              ← Download CoreELEC images here (~500 MB)
├── config/              ← Configuration files (4 files)
├── resources/           ← Supporting files
├── cache/               ← Downloaded files & build cache
├── logs/                ← Operation logs
└── .gitignore           ← Excludes large files from git
```

### Configuration Files (in data/config/)
1. **device.config** - S905W device parameters (USB IDs, thermal zones)
2. **build.config** - Cross-compilation settings (CMake, compiler flags)
3. **flashing.config** - USB flashing parameters (image URLs, boot timing)
4. **service.config** - Systemd service deployment settings

### Helper Scripts (in scripts/)
1. **init_data.sh** - Initialize data structure (already run ✓)
2. **load_config.sh** - Load all configurations as environment variables
3. **manage_cache.sh** - Manage cache size and cleanup
4. **flash.sh** - Updated flashing script using data directory

---

## 🚀 Quick Start Guide

### Step 1: Download OS Image

```bash
cd data/images

# Download CoreELEC (recommended)
wget https://releases.coreelec.org/CoreELEC-Amlogic.aarch64-latest.img.gz

# Extract
gunzip CoreELEC-Amlogic.aarch64-latest.img.gz

# Verify (~500 MB)
ls -lh CoreELEC-Amlogic.aarch64-latest.img
```

### Step 2: Check Configuration

```bash
# Load all configuration variables
source scripts/load_config.sh

# Verify key settings
echo $DEVICE_NAME          # Amlogic-S905W
echo $BUILD_DIR            # build-aarch64
echo $IMAGE_FILE           # CoreELEC-Amlogic.aarch64-latest.img
echo $IMAGES_DIR           # ./data/images
echo $LOGS_DIR             # ./data/logs
```

### Step 3: Flash S905W

```bash
# Using data-aware flashing script
bash scripts/flash.sh

# The script automatically:
# - Finds image in data/images/
# - Logs to data/logs/flashing.log
# - Reads config from data/config/
```

### Step 4: Deploy Service

```bash
# Find device IP (after boot)
ping -c 1 coreelec.local

# Deploy monitoring service
./setup_device.sh 192.168.1.XXX

# Logs to: data/logs/deployment.log
```

---

## 📝 Configuration Access

### In Shell Scripts

```bash
#!/bin/bash

# Load configuration
source scripts/load_config.sh

# Use any variable
echo "Device: $DEVICE_NAME"
echo "Image: $IMAGES_DIR/$IMAGE_FILE"
echo "Logs: $LOGS_DIR"
```

### Custom Environment (Optional)

```bash
# Copy template
cp data/.env.example data/.env

# Edit with your settings
nano data/.env

# Example:
PROJECT_ROOT=/Users/roebssie/Desktop/Box_Flasher
DEVICE_IP=192.168.1.100
DEVICE_USER=root
LOG_LEVEL=DEBUG
```

---

## 📦 File Organization

### Images (data/images/)
```
data/images/
├── CoreELEC-Amlogic.aarch64-latest.img  (500 MB after extraction)
├── CoreELEC-Amlogic.aarch64-latest.img.gz  (250 MB - optional backup)
└── README.md
```

### Configuration (data/config/)
```
data/config/
├── device.config       (Device: S905W USB IDs, thermal paths)
├── build.config        (Build: CMake, compiler, flags)
├── flashing.config     (Flash: image URLs, boot timing)
└── service.config      (Service: systemd, SSH, binary paths)
```

### Logs (data/logs/)
```
data/logs/
├── flashing.log       (From scripts/flash.sh)
├── deployment.log     (From setup_device.sh)
└── build.log          (From cmake/build processes)
```

### Cache (data/cache/)
```
data/cache/
├── downloaded/        (Downloaded files backup)
├── build/             (Build artifacts)
└── backups/           (Device backups, device configs)
```

---

## 🛠️ Useful Commands

### View Cache Usage
```bash
bash scripts/manage_cache.sh show

# Output shows:
# Downloaded files: 512 MB (3 files)
# Build artifacts: 245 MB
# Total cache size: 757 MB
```

### Clean Cache
```bash
# Remove specific cache
bash scripts/manage_cache.sh clean-downloaded
bash scripts/manage_cache.sh clean-build

# Remove all
bash scripts/manage_cache.sh clean-all
```

### Check Data Directory Size
```bash
du -sh data/

# Breakdown
du -sh data/*/
```

### View Recent Logs
```bash
# Flashing log
tail -50 data/logs/flashing.log

# Live tail
tail -f data/logs/deployment.log
```

### List Available Images
```bash
ls -lh data/images/*.img
```

---

## 🔐 Git Integration

### What's Tracked
✅ Configuration files (data/config/)
✅ Scripts (scripts/)
✅ Source code (src/)
✅ Build configuration (CMakeLists.txt, CMakeToolchain.cmake)

### What's NOT Tracked
❌ OS images (data/images/*.img - too large)
❌ Cache files (data/cache/)
❌ Logs (data/logs/)
❌ Environment files (data/.env)

**Already configured** via `data/.gitignore`

```bash
# Verify what's ignored
git status  # Should NOT show images or cache

# Track only configs
git add data/config/
git add scripts/
```

---

## 📋 Next Steps

### 1. Download Image ✓
```bash
cd data/images
wget https://releases.coreelec.org/CoreELEC-Amlogic.aarch64-latest.img.gz
gunzip CoreELEC-Amlogic.aarch64-latest.img.gz
```

### 2. Prepare Device
- Ensure S905W powered OFF
- Locate boot button (10-15 second hold time)
- Have USB-A to USB-A cable ready

### 3. Flash Device
```bash
bash scripts/flash.sh
```

### 4. Find Device IP
```bash
ping -c 1 coreelec.local
# or check router DHCP table
```

### 5. Deploy Service
```bash
./setup_device.sh 192.168.1.XXX
```

---

## 📚 Documentation Files

| File | Purpose |
|------|---------|
| **DATA_ORGANIZATION.md** | Complete data system documentation |
| **data/DATA_MANAGEMENT.md** | Data directory overview |
| **data/images/README.md** | Image management guide |
| **data/config/** | Configuration files (4 files) |
| **scripts/** | Helper scripts (4 scripts) |

---

## ⚙️ Configuration Reference

### device.config
```
DEVICE_NAME=Amlogic-S905W
USB_VENDOR_ID=0x1b8e
THERMAL_ZONE_PATH=/sys/class/thermal/thermal_zone0/temp
```

### build.config
```
CMAKE_SYSTEM_PROCESSOR=aarch64
CMAKE_CXX_STANDARD=17
BUILD_DIR=build-aarch64
```

### flashing.config
```
IMAGE_SOURCE_URL=https://releases.coreelec.org/...
BOOT_BUTTON_HOLD_TIME=15
USB_RETRY_ATTEMPTS=3
```

### service.config
```
SERVICE_BINARY=/opt/monitor_service
SERVICE_TYPE=oneshot
START_ON_BOOT=yes
```

---

## ✨ Key Features

✅ **Centralized** - All data in one directory  
✅ **Configurable** - Easy-to-edit config files  
✅ **Organized** - Logs, cache, images separated  
✅ **Versionable** - Configs tracked in git  
✅ **Portable** - Move project = move all data  
✅ **Scalable** - Add new config sections easily  
✅ **Automated** - Scripts handle setup/cleanup  
✅ **Safe** - Large files excluded from git  

---

## 🔍 Verify Setup

```bash
# Check data structure
tree data/

# Verify scripts
ls -la scripts/

# Check configurations
ls -la data/config/

# Verify executable permissions
file scripts/*.sh
```

---

## 💡 Tips

1. **Always load config** before running scripts:
   ```bash
   source scripts/load_config.sh
   ```

2. **Check logs** after operations:
   ```bash
   cat data/logs/flashing.log
   ```

3. **Keep backups** of configuration:
   ```bash
   cp -r data/config data/config.backup
   ```

4. **Monitor cache size**:
   ```bash
   bash scripts/manage_cache.sh show
   ```

5. **Archive old logs**:
   ```bash
   tar -czf data/logs.archive.tar.gz data/logs/
   ```

---

## ❓ Troubleshooting

### "Cannot find CoreELEC image"
```bash
# Download to correct location
cd data/images
wget https://releases.coreelec.org/CoreELEC-Amlogic.aarch64-latest.img.gz
gunzip CoreELEC-Amlogic.aarch64-latest.img.gz
```

### "Configuration variables not loading"
```bash
# Source configuration loader
source scripts/load_config.sh

# Verify
echo $DEVICE_NAME
```

### "Scripts not executable"
```bash
# Make executable
chmod +x scripts/*.sh
chmod +x *.sh
```

### "Need more space"
```bash
# Check usage
du -sh data/

# Clean cache
bash scripts/manage_cache.sh clean-all

# List large files
find data/ -size +100M -type f
```

---

## 📞 Summary

**Status:** ✅ Data Organization System Ready

All project data is now:
- **Stored** in `data/` directory
- **Configured** with 4 configuration files
- **Managed** with 4 helper scripts
- **Organized** by type (images, config, logs, cache)
- **Version controlled** (git tracked where appropriate)
- **Ready to use** for building and deployment

**Next action:** Download CoreELEC image to `data/images/` and begin flashing!

