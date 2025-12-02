# Cross-Platform Embedded System Monitoring Service

A minimal, high-performance system monitoring utility for the Amlogic S905W embedded device (Armbian/CoreELEC), built with cross-compilation from macOS (Apple Silicon), Linux, or Windows.

## 🚀 Quick Start

### Prerequisites
- **macOS** with Apple Silicon (M1/M2/M3) OR **Windows 10/11** (Git Bash/MinGW) OR **Linux**
- **CMake** (3.10+)
- **aarch64 Cross-Compiler** (see toolchain installation below)

### Toolchain Installation

```bash
# macOS (Homebrew - messense tap)
brew tap messense/macos-cross-toolchains && brew install messense/macos-cross-toolchains/aarch64-unknown-linux-gnu

# Linux/WSL (apt)
sudo apt-get install g++-aarch64-linux-gnu

# Windows: Install Arm GNU Toolchain 14.3.Rel1, add to PATH
# Download from: https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads
```

### Build in 3 Steps

```bash
# 1. Setup toolchain (one-time)
./tests/setup_toolchain.sh

# 2. Build for aarch64
cmake -DCMAKE_TOOLCHAIN_FILE=CMakeToolchain.cmake -B build-aarch64 .
cmake --build build-aarch64

# 3. Verify executable
file build-aarch64/monitor_service
# Output: ELF 64-bit LSB executable, ARM aarch64, statically linked
```

## 📦 Two Main Workflows

### 1. Build Workflow (C++ Cross-Compilation)
```bash
./tests/setup_toolchain.sh                                    # One-time setup
cmake -DCMAKE_TOOLCHAIN_FILE=CMakeToolchain.cmake -B build-aarch64 .
cmake --build build-aarch64
file build-aarch64/monitor_service  # Must show: aarch64, statically linked
```

### 2. Device Setup Workflow (Flash + Deploy)
```bash
./scripts/init_data.sh              # Create data/cache structure
./scripts/get_armbian_s905w.sh      # Download Armbian image
./usb_flash_s905w.sh                # Flash image (macOS interactive)
./setup_device.sh 192.168.1.100     # Deploy service to device
```

## ⚡ USB A-to-A Direct Flashing

> **⚠️ This project flashes directly to the S905W's internal eMMC via USB A-to-A cable** (NOT SD card/USB drive).

The device must be put into USB flashing mode (boot button or NAND_BOOT jumper) and connected via USB A male-to-male cable.

**Cross-platform flashing tools:**
- **macOS:** `usb_flash_s905w.sh` uses `aml_usb_flashing_tool` (Homebrew: `messense/amlogic-tools`)
- **Windows:** Official [Amlogic USB Burning Tool](https://github.com/nicknumb/amlogic_usb_burn_tool) (GUI, most reliable)
- **Linux:** `aml_usb_flashing_tool` or `pyamlboot` for direct USB flashing

## 📊 Features

### System Monitoring
- **CPU Temperature:** Reads from `/sys/class/thermal/thermal_zone0/temp`
- **RAM Usage:** Parses `/proc/meminfo` with detailed breakdown
- **Storage Health:** Lists mounted filesystems from `/proc/mounts`

### Build Characteristics
- ✅ Static linking (zero runtime dependencies)
- ✅ C++17 standard for performance and type safety
- ✅ Cross-compilation to aarch64 (ARMv8)
- ✅ Single executable file (~500-800 KB)
- ✅ POSIX-compliant for embedded Linux compatibility
- ✅ No `system()` calls or shell dependencies

## 📁 Project Structure

```
Box_Flasher/
├── src/main.cpp              # Monitoring logic (add sensors here)
├── include/monitor.h         # Header with testable parse functions
├── CMakeLists.txt            # Build config (don't add arch flags)
├── CMakeToolchain.cmake      # Cross-compiler paths, target system
├── scripts/
│   ├── load_config.sh        # Config loader for all shell scripts
│   ├── init_data.sh          # Create data/cache structure
│   └── get_armbian_s905w.sh  # Download Armbian image
├── data/config/
│   ├── device.config         # S905W hardware paths (THERMAL_ZONE_PATH, MEMINFO_PATH)
│   ├── build.config          # Compiler flags, build dir (BUILD_DIR=build-aarch64)
│   ├── flashing.config       # Image URLs, filenames
│   └── service.config        # Service installation paths
├── tests/
│   ├── test.sh               # 7-step build verification
│   ├── deployment_test.sh    # SCP + SSH remote execution
│   ├── setup_toolchain.sh    # Install cross-compiler
│   └── test.cpp              # Unit tests for parse functions
├── setup_device.sh           # One-command device deployment
├── usb_flash_s905w.sh        # Flash image (macOS interactive)
└── build-aarch64/            # Build output (generated)
    └── monitor_service       # Final executable
```

## 🔧 Configuration System

All scripts load config via `scripts/load_config.sh` which sources:
- `data/config/device.config` - S905W hardware paths
- `data/config/build.config` - Compiler flags, build dir (`BUILD_DIR=build-aarch64`)
- `data/config/flashing.config` - Image URLs, filenames
- `data/config/service.config` - Service installation paths
- `data/.env` - Local overrides (highest precedence, gitignored)

**Pattern:** Scripts source `load_config.sh` at startup, then use exported variables with fallback defaults:
```bash
if [ -f "./scripts/load_config.sh" ]; then source ./scripts/load_config.sh; fi
EXECUTABLE_PATH="${EXECUTABLE_PATH:-${BUILD_DIR:-build-aarch64}/monitor_service}"
```

## 📋 Output Example

```
=== System Monitoring Service ===
Target: Amlogic S905W Embedded Linux

CPU Temperature:
  Temperature: 48.50 °C

RAM Usage:
  Total:     512.00 MB
  Free:      234.56 MB
  Available: 289.34 MB
  Used:      222.66 MB (43.49%)

Storage Information:
Mounted filesystems (storage points):
  - /
  - /boot
  - /mnt/data

=== Monitoring Service Completed ===
```

## 🎯 Target System

**Device:** Amlogic S905W  
**OS:** Armbian or CoreELEC (embedded Linux)  
**Architecture:** aarch64 (ARM64)  
**Kernel:** Linux 5.4+ (typical for embedded distributions)

## 🔍 Common Mistakes

1. **Missing toolchain file** - Always use `-DCMAKE_TOOLCHAIN_FILE=CMakeToolchain.cmake`
2. **Wrong architecture flags location** - Put in `CMakeToolchain.cmake`, not `CMakeLists.txt`
3. **Dynamic linking** - If `file` output doesn't show "statically linked", rebuild
4. **Testing locally** - Binary only runs on aarch64 Linux, not macOS/Windows
5. **Adding external dependencies** - Forbidden; use only C++17 stdlib + POSIX

## 🔍 Troubleshooting

### Cross-compiler not found?
```bash
# macOS
brew tap messense/macos-cross-toolchains
brew install messense/macos-cross-toolchains/aarch64-unknown-linux-gnu

# Linux/WSL
sudo apt-get install g++-aarch64-linux-gnu
```

### Build fails?
```bash
# Clean and rebuild
rm -rf build-aarch64
cmake -DCMAKE_TOOLCHAIN_FILE=CMakeToolchain.cmake -B build-aarch64 .
cmake --build build-aarch64
```

### SSH connection issues?
```bash
# Find your device IP
arp -a | grep -i amlogic
# Or use Nmap
nmap -sn 192.168.1.0/24
```

## ⚙️ Development

### Adding Features
1. Edit `src/main.cpp`
2. Rebuild: `cmake --build build-aarch64`
3. Test on device: `./tests/deployment_test.sh`

### Running Unit Tests
```bash
# Build tests for host (not cross-compiled)
cmake -DBUILD_TESTS=ON -B build-tests .
cmake --build build-tests
./build-tests/test_runner
```

### Verification Command
```bash
./tests/test.sh  # Runs: CMake check → compiler check → build → architecture verify
```

## 📖 Documentation

For detailed information, see:
- **[reports/REPORT.md](reports/REPORT.md)** - Complete phase-by-phase documentation
- **[reports/QUICKSTART.md](reports/QUICKSTART.md)** - Fastest path to verification

## 🔗 Resources

- [CMake Cross-Compilation](https://cmake.org/cmake/help/latest/manual/cmake-toolchains.7.html)
- [Amlogic S905W Information](https://github.com/khadas/fenix)
- [Armbian Project](https://www.armbian.com/)
- [CoreELEC Project](https://coreelec.org/)

---

**Status:** ✓ Complete and Verified  
**Build Hosts:** macOS (Apple Silicon), Linux, Windows (Git Bash/MinGW)  
**Target:** aarch64 Embedded Linux (Armbian/CoreELEC on S905W)
