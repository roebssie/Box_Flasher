# 📑 Complete Project Index

## Project: Amlogic S905W Monitoring Service
**Status:** ✅ Data Organization Complete  
**Last Updated:** November 27, 2025

---

## 🏗️ Project Structure

```
Box_Flasher/
├── 📦 data/                          [NEW] Centralized data directory
│   ├── images/                       ← Download CoreELEC images
│   ├── config/                       ← 4 configuration files
│   ├── resources/                    ← Supporting files
│   ├── cache/                        ← Build/download cache
│   ├── logs/                         ← Operation logs
│   ├── .gitignore
│   ├── .env.example
│   └── DATA_MANAGEMENT.md
│
├── 🔧 scripts/                       [NEW] Helper scripts
│   ├── init_data.sh                  ← Initialize data structure
│   ├── load_config.sh                ← Load configurations
│   ├── manage_cache.sh               ← Cache management
│   └── flash.sh                      ← Data-aware flashing
│
├── 📄 Documentation (Root)
│   ├── DATA_SETUP_COMPLETE.md        [NEW] Setup summary
│   ├── DATA_ORGANIZATION.md          [NEW] Complete guide
│   ├── README.md                     ← Project overview
│   ├── CMakeLists.txt
│   ├── CMakeToolchain.cmake
│   └── ... (other docs)
│
├── 🔨 src/
│   └── main.cpp                      ← Monitoring service source
│
├── 🏗️ build-aarch64/
│   └── monitor_service               ← Compiled binary
│
├── 🧪 tests/
│   ├── test.sh
│   ├── deployment_test.sh
│   └── ...
│
├── 📚 reports/
│   └── (Various documentation)
│
└── 📋 .github/
    └── copilot-instructions.md
```

---

## 📦 NEW: Data Directory System

### Structure
```
data/
├── images/          [~500 MB]  CoreELEC/LibreELEC images
├── config/          [~50 KB]   Configuration files
├── resources/       [empty]    Supporting files
├── cache/           [variable] Build/download cache
│   ├── downloaded/  [~250 MB]  Downloaded images backup
│   ├── build/       [~200 MB]  Build artifacts
│   └── backups/     [variable] Device backups
└── logs/            [variable] Operation logs
```

### Configuration Files (data/config/)
1. **device.config** - S905W USB IDs, thermal paths, network
2. **build.config** - CMake, compiler, cross-compilation settings
3. **flashing.config** - Image URLs, boot timing, USB parameters
4. **service.config** - Systemd, SSH, binary deployment settings

**Format:** Key=value format, automatically sourced by scripts

### Helper Scripts (scripts/)
1. **init_data.sh** - Initialize data structure ✅ Already run
2. **load_config.sh** - Load all configurations as environment vars
3. **manage_cache.sh** - Manage/cleanup cache files
4. **flash.sh** - Updated flashing using data directory

---

## 🎯 Current Project Status

| Component | Status | Location |
|-----------|--------|----------|
| Source Code | ✅ Complete | `src/main.cpp` |
| Build System | ✅ Complete | `CMakeLists.txt`, `CMakeToolchain.cmake` |
| Binary | ✅ Built | `build-aarch64/monitor_service` (8.6 MB) |
| Configuration | ✅ Complete | `data/config/` (4 files) |
| Data Organization | ✅ Complete | `data/` directory |
| Helper Scripts | ✅ Complete | `scripts/` directory |
| Documentation | ✅ Complete | `DATA_ORGANIZATION.md`, `DATA_SETUP_COMPLETE.md` |

---

## 📋 Key Files Reference

### Documentation Files
```
DATA_SETUP_COMPLETE.md ........... Summary of new data system
DATA_ORGANIZATION.md ............ Complete data management guide
data/DATA_MANAGEMENT.md ......... Data directory overview
data/images/README.md ........... Image management guide
data/.env.example ............... Environment template
data/.gitignore ................. Git ignore rules
```

### Configuration Files
```
data/config/device.config ....... Device settings (S905W)
data/config/build.config ........ Build parameters
data/config/flashing.config ..... Flashing settings
data/config/service.config ...... Service configuration
```

### Scripts
```
scripts/init_data.sh ............ Initialize data structure [✅ RUN]
scripts/load_config.sh .......... Load configurations
scripts/manage_cache.sh ......... Cache management
scripts/flash.sh ................ Flashing with data dir
```

### Source Code
```
src/main.cpp .................... Monitoring service (174 lines)
tests/test.sh ................... Build verification
tests/deployment_test.sh ........ Deployment testing
```

### Build Output
```
build-aarch64/monitor_service ... Compiled binary (aarch64, static)
CMakeLists.txt .................. Build configuration
CMakeToolchain.cmake ............ Cross-compiler configuration
```

---

## 🚀 Getting Started (Quick Path)

### 1. Initialize System (Already Done ✓)
```bash
bash scripts/init_data.sh
```

### 2. Download OS Image
```bash
cd data/images
wget https://releases.coreelec.org/CoreELEC-Amlogic.aarch64-latest.img.gz
gunzip CoreELEC-Amlogic.aarch64-latest.img.gz
```

### 3. Load Configuration
```bash
source scripts/load_config.sh
echo $DEVICE_NAME
echo $IMAGE_FILE
```

### 4. Flash Device
```bash
bash scripts/flash.sh
```

### 5. Deploy Service
```bash
./setup_device.sh 192.168.1.XXX
```

---

## 📊 Complete Operation Workflow

```
┌─────────────────────────────────────┐
│ 1. Initialize Data System           │
│    bash scripts/init_data.sh         │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│ 2. Download CoreELEC Image          │
│    cd data/images && wget ...        │
│    gunzip ...                        │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│ 3. Load Configuration               │
│    source scripts/load_config.sh     │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│ 4. Put S905W in USB Flashing Mode   │
│    Hold boot button 10-15 seconds    │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│ 5. Flash Device                     │
│    bash scripts/flash.sh             │
│    → Reads from data/images/         │
│    → Logs to data/logs/flashing.log  │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│ 6. Wait for Boot (3 minutes)        │
│    Find device: ping coreelec.local  │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│ 7. Deploy Service                   │
│    ./setup_device.sh 192.168.1.XXX   │
│    → Logs to data/logs/deployment    │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│ ✅ COMPLETE: Service Running!       │
│    Systemd service auto-boots       │
│    Monitor data on device           │
└─────────────────────────────────────┘
```

---

## 🔗 File Dependencies

### Configuration Chain
```
data/config/device.config
data/config/build.config        } All loaded by
data/config/flashing.config     } scripts/load_config.sh
data/config/service.config
         ↓
  Environment variables available
         ↓
  Used by scripts and applications
```

### Build Chain
```
CMakeToolchain.cmake ─→ Cross-compiler setup
        ↓
  CMakeLists.txt ────→ Build configuration
        ↓
  src/main.cpp ──────→ Source code
        ↓
  build-aarch64/monitor_service ← Binary output
```

### Deployment Chain
```
build-aarch64/monitor_service ─→ SCP to device
        ↓
  setup_device.sh ───────────→ Deploy to /opt/
        ↓
  /etc/systemd/system/monitor.service ← Service file
        ↓
  Service running on boot ← Auto-start
```

---

## 💾 Data Management

### Cache Commands
```bash
# View cache status
bash scripts/manage_cache.sh show

# Clean specific cache
bash scripts/manage_cache.sh clean-downloaded
bash scripts/manage_cache.sh clean-build

# Clean everything
bash scripts/manage_cache.sh clean-all
```

### Log Access
```bash
# Flashing log
cat data/logs/flashing.log

# Deployment log
tail -50 data/logs/deployment.log

# Live tail
tail -f data/logs/build.log
```

### Image Management
```bash
# List images
ls -lh data/images/

# Check size
du -sh data/images/

# Compress for storage
gzip data/images/CoreELEC-*.img
```

---

## 🔐 Git Integration

### What's Tracked ✅
- `data/config/` - Configuration files
- `scripts/` - Helper scripts
- `src/` - Source code
- CMake files
- Documentation

### What's Ignored ❌
- `data/images/*.img` - Large OS images
- `data/cache/` - Cache files
- `data/logs/` - Log files
- `data/.env` - Local environment
- `build-aarch64/` - Build output

**Already configured** in `data/.gitignore`

---

## 📐 Architecture Overview

### Cross-Compilation Pipeline
```
macOS (M1/M2/M3) Host
    ↓
aarch64-unknown-linux-gnu toolchain
    ↓
C++17 source code (src/main.cpp)
    ↓
Static aarch64 ELF binary (build-aarch64/monitor_service)
    ↓
Amlogic S905W Device (CoreELEC/LibreELEC)
```

### Monitoring Functions
```
┌─────────────────────────────────────┐
│   Monitor Service Binary            │
├─────────────────────────────────────┤
│ ├─ CPU Temperature                  │
│ │  └─ /sys/class/thermal/.../temp   │
│ ├─ RAM Usage                        │
│ │  └─ /proc/meminfo                 │
│ └─ Storage Health                   │
│    └─ /proc/mounts                  │
└─────────────────────────────────────┘
```

---

## ⚙️ Configuration Reference

### Device Settings (device.config)
```
DEVICE_NAME=Amlogic-S905W
DEVICE_ARCH=aarch64
USB_VENDOR_ID=0x1b8e
THERMAL_ZONE_PATH=/sys/class/thermal/thermal_zone0/temp
```

### Build Settings (build.config)
```
CMAKE_SYSTEM_PROCESSOR=aarch64
CMAKE_CXX_STANDARD=17
BUILD_DIR=build-aarch64
STATIC_LINKING=YES
```

### Flashing Settings (flashing.config)
```
IMAGE_SOURCE_URL=https://releases.coreelec.org/...
IMAGE_SIZE_EXPECTED=500M
BOOT_BUTTON_HOLD_TIME=15
USB_RETRY_ATTEMPTS=3
```

### Service Settings (service.config)
```
SERVICE_BINARY=/opt/monitor_service
SERVICE_TYPE=oneshot
START_ON_BOOT=yes
SSH_PORT=22
```

---

## 🎓 Learning Resources

### For Building
- `CMakeLists.txt` - Build configuration
- `CMakeToolchain.cmake` - Cross-compiler setup
- `.github/copilot-instructions.md` - Architecture guide

### For Flashing
- `DATA_ORGANIZATION.md` - Complete guide
- `data/images/README.md` - Image management
- `USB_A_TO_A_FLASHING.md` - USB-A specific guide

### For Deployment
- `DEVICE_SETUP.md` - Service setup options
- `setup_device.sh` - Deployment script
- `data/config/service.config` - Service configuration

### For Monitoring
- `src/main.cpp` - Source code
- System monitoring functions documented in code
- Output format in main() function

---

## 🔧 Development Workflow

### Adding New Feature
```
1. Modify src/main.cpp
2. Update CMakeLists.txt if needed
3. Rebuild: cmake --build build-aarch64
4. Test locally (if applicable)
5. Deploy: ./setup_device.sh $DEVICE_IP
```

### Updating Configuration
```
1. Edit data/config/*.config
2. Changes take effect next deployment
3. Commit to git: git add data/config/
```

### Managing Cache
```
1. Check usage: bash scripts/manage_cache.sh show
2. Clean if needed: bash scripts/manage_cache.sh clean-all
3. Re-download images if cleared
```

---

## ✅ Verification Checklist

- [x] Data directory created
- [x] Configuration files in place
- [x] Helper scripts created and executable
- [x] Environment template created
- [x] Git ignore configured
- [x] Directory structure verified
- [x] Binary ready (build-aarch64/monitor_service)
- [x] Documentation complete

---

## 📞 Next Steps

### Immediate (5 minutes)
1. ✅ Data system initialized
2. Download CoreELEC image to `data/images/`
3. Verify image exists: `ls -lh data/images/`

### Short-term (15 minutes)
1. Load configuration: `source scripts/load_config.sh`
2. Put S905W in USB flashing mode
3. Connect USB cable
4. Run: `bash scripts/flash.sh`

### Medium-term (30 minutes)
1. Wait for device to boot
2. Find device IP: `ping coreelec.local`
3. Deploy service: `./setup_device.sh 192.168.1.XXX`
4. Verify: `systemctl status monitor.service`

---

## 📞 Support Resources

### Troubleshooting
- See `DATA_ORGANIZATION.md` → Troubleshooting section
- See `USB_A_TO_A_FLASHING.md` → Troubleshooting Matrix
- Check logs: `data/logs/`

### Configuration
- All configs in `data/config/` (key=value format)
- Override with `data/.env` file
- Load with: `source scripts/load_config.sh`

### Maintenance
- Cache management: `bash scripts/manage_cache.sh`
- Log rotation: Logs in `data/logs/`
- Backups: Stored in `data/cache/backups/`

---

## 🎯 Project Summary

**Status:** ✅ READY FOR PRODUCTION

**Data System:** Fully organized and centralized  
**Configuration:** 4 config files covering all parameters  
**Scripts:** 4 helper scripts for automation  
**Binary:** Ready for deployment (aarch64, static)  
**Documentation:** Complete with guides and references  

**Next Action:** Download CoreELEC image to `data/images/` and flash S905W!

---

**Last Updated:** November 27, 2025  
**Version:** 1.0 - Data Organization Complete  
**Maintainer:** GitHub Copilot
