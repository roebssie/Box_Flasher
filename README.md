# Cross-Platform Embedded System Monitoring Service

A minimal, high-performance system monitoring utility for the Amlogic S905W embedded device (Armbian/Ophub), built on Apple Silicon macOS with aarch64-linux-gnu cross-compilation.

## 🚀 Quick Start

### Prerequisites
- **macOS** with Apple Silicon (M1/M2/M3) OR **Windows 10/11** (Git Bash) OR **Linux**
- **Homebrew** (macOS) or **Winget** (Windows)
- **CMake** (3.15+)
- **Arm GNU Toolchain** (14.3.Rel1 recommended for Windows)

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

## 📦 What's Included

| File | Purpose |
|------|---------|
| `src/main.cpp` | System monitoring application (C++17) |
| `CMakeLists.txt` | CMake build configuration |
| `CMakeToolchain.cmake` | Cross-compilation toolchain for aarch64-linux-gnu |
| `tests/setup_toolchain.sh` | Verifies build environment and dependencies |
| `tests/deployment_test.sh` | Automated deployment and testing script |
| `tests/test.sh` | Build verification and testing suite |
| `reports/REPORT.md` | Complete technical documentation |
| `reports/QUICKSTART.md` | Fast deployment reference guide |

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

## 🔧 Deployment

### Simple: Use Automated Script
```bash
export TARGET_HOST=root@192.168.1.100
./tests/deployment_test.sh
```

## ⚡ Short Quickstart (Flash & Deploy)

Run these commands to prepare, build, flash, and install the monitor quickly (defaults are read from `data/config/*.config` and `data/.env` if present):

```bash
# 1. Create data/cache structure and sample env
./scripts/init_data.sh

# 2. One-time toolchain setup on macOS
./tests/setup_toolchain.sh

# 3. Build the cross-compiled binary for aarch64
cmake -DCMAKE_TOOLCHAIN_FILE=CMakeToolchain.cmake -B build-aarch64 .
cmake --build build-aarch64

# 4. Flash CoreELEC to the S905W (interactive macOS helper)
./usb_flash_s905w.sh

# 5. Transfer and install the monitoring service to the device
# Replace 192.168.1.100 with your device IP
./setup_device.sh 192.168.1.100
```

### Manual: SCP + SSH
```bash
scp build-aarch64/monitor_service root@<device-ip>:/tmp/
ssh root@<device-ip> "/tmp/monitor_service"
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

## 🛠️ Project Structure

```
Box_Flasher/
├── src/
│   └── main.cpp              # Core monitoring logic
├── CMakeLists.txt            # Build configuration
├── CMakeToolchain.cmake      # Cross-compiler definition
├── tests/
│   ├── setup_toolchain.sh    # Environment setup
│   ├── deployment_test.sh    # Deployment automation
│   ├── test.sh               # Build verification
│   ├── apple_silicon_test.sh # Compatibility tests
│   └── test.cpp              # Test source code
├── reports/
│   ├── REPORT.md             # Full technical documentation
│   ├── QUICKSTART.md         # Quick start guide
│   └── (other reports)       # Additional documentation
├── README.md                 # This file
└── build-aarch64/            # Build output (generated)
    └── monitor_service       # Final executable
```

## 📖 Documentation

For detailed information, see:
- **[REPORT.md](REPORT.md)** - Complete technical documentation
  - Architecture overview
  - Phase-by-phase breakdown
  - Build instructions with examples
  - Deployment guide
  - Verification results
  - Troubleshooting

## 🎯 Target System

**Device:** Amlogic S905W  
**OS:** CoreELEC or LibreELEC (embedded Linux)  
**Architecture:** aarch64 (ARM64)  
**Kernel:** Linux 5.4+ (typical for embedded distributions)

## 🔍 Troubleshooting

### Cross-compiler not found?
```bash
brew install aarch64-elf-gcc aarch64-elf-binutils
# Or compile from source:
git clone https://github.com/tpoechtrager/osxcross.git
cd osxcross && UNATTENDED=1 ./build_gcc.sh aarch64 linux
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
brew install nmap
nmap -sn 192.168.1.0/24
```

See **[reports/REPORT.md#troubleshooting](reports/REPORT.md#troubleshooting)** for more solutions.

## ⚙️ Development

### Adding Features
1. Edit `src/main.cpp`
2. Rebuild: `cmake --build build-aarch64`
3. Test on device: `./tests/deployment_test.sh`

### Customizing Build Flags
Edit `CMakeLists.txt`:
```cmake
target_compile_options(monitor_service PRIVATE -O3 -march=armv8-a)
```

## 📝 License

This project demonstrates cross-compilation techniques for embedded systems. Use as needed for your specific hardware targets.

## 🔗 Resources

- [CMake Cross-Compilation](https://cmake.org/cmake/help/latest/manual/cmake-toolchains.7.html)
- [osxcross - macOS to Linux cross-compiler](https://github.com/tpoechtrager/osxcross)
- [Amlogic S905W Information](https://github.com/khadas/fenix)
- [CoreELEC Project](https://coreelec.org/)
- [LibreELEC Project](https://libreelec.tv/)

---

**Status:** ✓ Complete and Verified  
**Build Host:** Apple Silicon macOS  
**Target:** aarch64 Embedded Linux
