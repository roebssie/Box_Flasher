# 📦 Data Organization & Management System

## Overview

All project data is now **centrally located** in the `/data` directory within the codebase. This includes:
- OS images for flashing
- Configuration files
- Build artifacts
- Logs and cache
- Resources and documentation

---

## Directory Structure

```
Box_Flasher/
├── data/                              # 📦 ALL PROJECT DATA
│   ├── images/                        # 🖼️ OS images for S905W
│   │   ├── CoreELEC-Amlogic.aarch64-latest.img  (~500 MB)
│   │   └── README.md
│   │
│   ├── config/                        # ⚙️ Configuration files
│   │   ├── device.config              # Device settings
│   │   ├── build.config               # Build parameters
│   │   ├── flashing.config            # Flashing settings
│   │   └── service.config             # Service configuration
│   │
│   ├── resources/                     # 📚 Supporting files
│   │   ├── monitor.service            # Systemd service
│   │   └── flashing-tools/            # Tool references
│   │
│   ├── cache/                         # 💾 Build/download cache
│   │   ├── downloaded/                # Downloaded images cache
│   │   ├── build/                     # Build artifacts
│   │   └── backups/                   # Backup files
│   │
│   ├── logs/                          # 📝 Operation logs
│   │   ├── flashing.log
│   │   ├── deployment.log
│   │   └── build.log
│   │
│   ├── .env.example                   # Environment template
│   ├── .gitignore                     # Git ignore rules
│   └── DATA_MANAGEMENT.md             # This file
│
├── scripts/                           # 🔧 Helper scripts
│   ├── init_data.sh                   # Initialize data structure
│   ├── load_config.sh                 # Load configurations
│   ├── manage_cache.sh                # Cache management
│   └── flash.sh                       # Flash with data dir
│
├── build-aarch64/                     # Build output
│   └── monitor_service                # Compiled binary
│
└── src/
    └── main.cpp                       # Source code
```

---

## Quick Start

### 1. Initialize Data System

```bash
# Create directories and load configs
bash scripts/init_data.sh

# Result: data/ directory fully initialized
```

### 2. Load Configuration

```bash
# In any script or terminal session
source scripts/load_config.sh

# Now all config variables available:
echo $DEVICE_NAME          # Amlogic-S905W
echo $BUILD_DIR            # build-aarch64
echo $IMAGES_DIR           # ./data/images
echo $LOGS_DIR             # ./data/logs
```

### 3. Download OS Image

```bash
cd data/images

# Download CoreELEC image
wget https://releases.coreelec.org/CoreELEC-Amlogic.aarch64-latest.img.gz

# Extract
gunzip CoreELEC-Amlogic.aarch64-latest.img.gz

# Verify
ls -lh CoreELEC-Amlogic.aarch64-latest.img
```

### 4. Flash Device

```bash
# Using new data-aware script
bash scripts/flash.sh

# Image automatically read from data/images/
# Logs automatically written to data/logs/flashing.log
```

---

## Configuration Files

Each config file is key=value format, automatically sourced:

### device.config
Device-specific settings (S905W parameters, USB IDs, thermal paths)

```bash
source scripts/load_config.sh
echo $USB_VENDOR_ID        # 0x1b8e
echo $THERMAL_ZONE_PATH    # /sys/class/thermal/thermal_zone0/temp
```

### build.config
Cross-compilation settings (CMake, compiler flags, toolchain)

```bash
echo $CMAKE_SYSTEM_PROCESSOR  # aarch64
echo $CMAKE_CXX_STANDARD      # 17
echo $BUILD_DIR               # build-aarch64
```

### flashing.config
USB flashing parameters (image URLs, boot timing, USB IDs)

```bash
echo $IMAGE_SOURCE_URL     # https://releases.coreelec.org/...
echo $BOOT_BUTTON_HOLD_TIME  # 15 seconds
```

### service.config
Service deployment settings (systemd, SSH, binary paths)

```bash
echo $SERVICE_BINARY       # /opt/monitor_service
echo $SERVICE_TYPE         # oneshot
```

---

## Environment Variables

Create `data/.env` to override defaults:

```bash
# Copy template
cp data/.env.example data/.env

# Edit with your settings
nano data/.env

# Example content:
PROJECT_ROOT=/Users/roebssie/Desktop/Box_Flasher
DEVICE_IP=192.168.1.100
DEVICE_USER=root
IMAGE_FILE=CoreELEC-Amlogic.aarch64-latest.img
LOG_LEVEL=DEBUG
```

Load in any script:
```bash
source data/.env
source scripts/load_config.sh
```

---

## Image Management

### Download Images to data/images/

```bash
cd data/images

# CoreELEC (recommended)
wget https://releases.coreelec.org/CoreELEC-Amlogic.aarch64-latest.img.gz
gunzip CoreELEC-Amlogic.aarch64-latest.img.gz

# LibreELEC (alternative)
wget https://releases.libreelec.tv/LibreELEC-Generic.aarch64-latest.img.gz
gunzip LibreELEC-Generic.aarch64-latest.img.gz
```

### Verify Images

```bash
cd data/images

# Check size
ls -lh *.img

# Verify integrity (should be ext4 image)
file CoreELEC-Amlogic.aarch64-latest.img

# Calculate checksum
md5sum CoreELEC-Amlogic.aarch64-latest.img
```

### Manage Storage

```bash
# View image directory size
du -sh data/images/

# Compress to save space (50% reduction)
gzip -k data/images/CoreELEC-Amlogic.aarch64-latest.img

# Remove old versions
rm data/images/CoreELEC-Amlogic.aarch64-20.4.x.img
```

---

## Cache Management

### View Cache

```bash
bash scripts/manage_cache.sh show

# Output:
# Downloaded files: 512 MB (2 files)
# Build artifacts: 245 MB (150 files)
# Backups: 128 MB (3 files)
# Total cache size: 885 MB
```

### Clean Specific Cache

```bash
# Remove downloaded files
bash scripts/manage_cache.sh clean-downloaded

# Remove build artifacts
bash scripts/manage_cache.sh clean-build

# Remove old backups (>30 days)
bash scripts/manage_cache.sh clean-backups

# Remove everything
bash scripts/manage_cache.sh clean-all
```

### Auto-Cleanup

```bash
# Add to crontab for daily cleanup
# 0 2 * * * cd /Users/roebssie/Desktop/Box_Flasher && bash scripts/manage_cache.sh clean-old-backups
```

---

## Logging

All operations log to `data/logs/`:

### Flashing Logs

```bash
# View flashing log
cat data/logs/flashing.log

# Watch live
tail -f data/logs/flashing.log
```

### Deployment Logs

```bash
# View deployment log
cat data/logs/deployment.log

# Search for errors
grep ERROR data/logs/deployment.log
```

### Build Logs

```bash
# View build log
cat data/logs/build.log

# Extract warnings
grep -i warning data/logs/build.log
```

### Log Rotation

```bash
# Logs are kept for 30 days by default
# Set in data/config/flashing.config:
# LOG_RETENTION_DAYS=30

# Manual cleanup
find data/logs/ -mtime +30 -delete
```

---

## Using Data-Aware Scripts

### Updated usb_flash_s905w.sh

```bash
# Uses data/images/ for images
# Logs to data/logs/flashing.log
bash usb_flash_s905w.sh
```

### Updated setup_device.sh

```bash
# Binary deployed from build-aarch64/
# Configuration read from data/config/
./setup_device.sh 192.168.1.100
```

### New flash.sh

```bash
# Smart flashing with data directory
bash scripts/flash.sh

# Automatically:
# - Finds image in data/images/
# - Logs to data/logs/flashing.log
# - Reads config from data/config/
```

---

## Git Configuration

### .gitignore for data/

Already configured, but key entries:

```
# data/.gitignore (auto-created)
*.img                    # OS images (large)
*.img.gz
*.iso
cache/**                 # Cache files
logs/**                  # Logs
.env                     # Local env
.env.local
```

### Tracking Configuration Only

```bash
# Configuration files ARE tracked (version controlled)
git add data/config/

# But images and cache are NOT
git add -n data/images/  # Shows nothing (ignored)
git add -n data/cache/   # Shows nothing (ignored)
```

### Optional: Git LFS for Images

```bash
# If you want to version control images
git lfs install
git lfs track "data/images/*.img"
git add .gitattributes
git add data/images/
```

---

## Updating Scripts to Use Data Directory

### In shell scripts:

```bash
#!/bin/bash

# Load configuration from data/
source scripts/load_config.sh

# Now use variables:
IMAGE_FILE="$IMAGES_DIR/CoreELEC-Amlogic.aarch64-latest.img"
LOG_FILE="$LOGS_DIR/deployment.log"

# Store results in data/
cp build-aarch64/monitor_service "$DATA_DIR/resources/"
```

### In CMakeLists.txt:

```cmake
# Reference data directory for resources
set(RESOURCES_DIR "${CMAKE_SOURCE_DIR}/data/resources")
set(CONFIG_DIR "${CMAKE_SOURCE_DIR}/data/config")

# Use in custom targets
add_custom_command(TARGET monitor_service POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            ${CMAKE_BINARY_DIR}/monitor_service
            ${RESOURCES_DIR}/
)
```

---

## Directory Size Management

### Check sizes

```bash
# Overall project size
du -sh .

# Breakdown by directory
du -sh */ | sort -h

# Detailed data breakdown
du -sh data/**/ | sort -h
```

### Large file finder

```bash
# Find files larger than 100MB
find data/ -size +100M -type f

# Find files larger than 1MB
find data/ -size +1M -type f | head -20
```

### Cleanup strategies

```bash
# Remove cached images over 30 days old
find data/cache/downloaded -mtime +30 -delete

# Remove temporary build artifacts
find data/cache/build -name "*.o" -delete

# Archive old logs
tar -czf data/logs/archive_$(date +%Y%m%d).tar.gz data/logs/*.log
rm data/logs/*.log
```

---

## Common Operations

### Complete setup from scratch

```bash
# 1. Initialize
bash scripts/init_data.sh

# 2. Download image
cd data/images
wget https://releases.coreelec.org/CoreELEC-Amlogic.aarch64-latest.img.gz
gunzip CoreELEC-Amlogic.aarch64-latest.img.gz

# 3. Build project
cmake -DCMAKE_TOOLCHAIN_FILE=CMakeToolchain.cmake -B build-aarch64 .
cmake --build build-aarch64

# 4. Flash device
bash scripts/flash.sh

# 5. Deploy service
./setup_device.sh 192.168.1.100
```

### Backup all project data

```bash
# Create timestamped backup
tar -czf Box_Flasher_$(date +%Y%m%d_%H%M%S).tar.gz \
    --exclude=data/cache \
    --exclude=build-aarch64 \
    .

# Size will be ~2-3MB (config + source only)
ls -lh Box_Flasher_*.tar.gz
```

### Move entire project

```bash
# All data moves with project
mv /Users/roebssie/Desktop/Box_Flasher /new/location/

# Everything still works
cd /new/location/Box_Flasher
bash scripts/init_data.sh
```

---

## Troubleshooting

### "Cannot find image"

```bash
# Check if image exists
ls -la data/images/

# If missing, download
cd data/images
wget https://releases.coreelec.org/CoreELEC-Amlogic.aarch64-latest.img.gz
gunzip CoreELEC-Amlogic.aarch64-latest.img.gz
```

### "Config variables not loading"

```bash
# Verify load_config.sh exists
ls -la scripts/load_config.sh

# Manually source
source scripts/load_config.sh

# Check variables
echo $DEVICE_NAME
echo $BUILD_DIR
```

### "Permission denied" on scripts

```bash
# Make scripts executable
chmod +x scripts/*.sh
chmod +x *.sh

# Verify
ls -la scripts/
```

### "Disk space issues"

```bash
# Check available space
df -h

# Clean cache
bash scripts/manage_cache.sh clean-all

# Remove old image versions
rm data/images/CoreELEC-*-old.img
```

---

## Summary

✅ **All data centralized** in `data/` directory  
✅ **Configuration files** version-controlled in `data/config/`  
✅ **Images stored** in `data/images/` (~500 MB each)  
✅ **Logs organized** in `data/logs/`  
✅ **Cache managed** in `data/cache/`  
✅ **Scripts updated** to use data directory  
✅ **Environment support** via `.env` files  
✅ **Git ignore configured** for large files  

---

**Next Steps:**
1. Run `bash scripts/init_data.sh` to initialize
2. Download images to `data/images/`
3. Use new data-aware scripts for flashing/deployment
4. Keep all project data within codebase

