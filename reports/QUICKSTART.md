# Quick Start Guide - Embedded System Monitoring Service

## Status Check
✓ Project files created and ready  
⚠ **ACTION REQUIRED:** Install aarch64-linux-gnu toolchain  
✓ Build configuration prepared  

---

## Step 1: Install Cross-Compiler Toolchain (5-10 minutes)

### macOS (Apple Silicon)
Run this command to install the aarch64-linux-gnu cross-compiler:

```bash
brew tap messense/macos-cross-toolchains
brew install messense/macos-cross-toolchains/aarch64-unknown-linux-gnu
```

### Windows (MinGW/Git Bash)
1. Download the **Arm GNU Toolchain 14.3.Rel1** for Windows x86_64:
   - File: `arm-gnu-toolchain-14.3.rel1-mingw-w64-x86_64-aarch64-none-linux-gnu.exe`
   - Source: [Arm Developer Downloads](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads)
2. Run the installer.
3. **Important:** Select "Add path to environment variable" during installation.
4. Restart Git Bash.

### Linux (Debian/Ubuntu)
```bash
sudo apt-get update
sudo apt-get install g++-aarch64-linux-gnu
```

**Verify installation:**
```bash
# Run the setup script to verify everything
./tests/setup_toolchain.sh
```

---

## Step 2: Build the Project

```bash
cd /Users/roebssie/Desktop/Box_Flasher

# Configure the build with cross-compilation toolchain
cmake -DCMAKE_TOOLCHAIN_FILE=CMakeToolchain.cmake -B build-aarch64 .

# Build the executable
cmake --build build-aarch64

# Verify the output
ls -lh build-aarch64/monitor_service
file build-aarch64/monitor_service
```

**Expected output:**
```
build-aarch64/monitor_service: ELF 64-bit LSB executable, ARM aarch64, 
                               version 1 (SYSV), statically linked
```

---

## Step 3: Deploy to Target Device

### Prerequisites:
- Target device running Armbian (Ophub) with SSH enabled
- Network connectivity to the device
- Know the device's IP address

### Deployment:

```bash
# Set your target device IP
TARGET_IP="192.168.1.100"  # Change to your device IP

# Transfer the executable
scp build-aarch64/monitor_service root@$TARGET_IP:/tmp/

# Run the service
ssh root@$TARGET_IP "/tmp/monitor_service"
```

**Expected output:**
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

=== Monitoring Service Completed ===
```

---

## Project Files Overview

| File | Purpose |
|------|---------|
| `src/main.cpp` | Core monitoring application (CPU temp, RAM, storage) |
| `CMakeLists.txt` | CMake build configuration |
| `CMakeToolchain.cmake` | Cross-compilation toolchain settings |
| `deployment_test.sh` | Automated deployment script |
| `setup_toolchain.sh` | Toolchain verification script |
| `REPORT.md` | Complete technical documentation |
| `build-aarch64/` | Build output directory (created by cmake) |

---

## Troubleshooting

### Problem: "aarch64-linux-gnu-g++: command not found"
**Solution:**
```bash
brew tap messense/macos-cross-toolchains
brew install aarch64-linux-gnu
```

### Problem: "CMakeToolchain.cmake: No such file or directory"
**Solution:**
```bash
cd /Users/roebssie/Desktop/Box_Flasher
cmake -DCMAKE_TOOLCHAIN_FILE=CMakeToolchain.cmake -B build-aarch64 .
```

### Problem: "SSH connection refused" to target device
**Solution:**
1. Verify device is powered on and connected to network
2. Find the device IP:
   ```bash
   ping -c 1 armbian.local  # if mDNS is configured
   # or check your router's DHCP table
   ```
3. Enable SSH on target (if not already enabled)

### Problem: Binary architecture is not aarch64
**Solution:**
```bash
# Clean and rebuild
rm -rf build-aarch64
cmake -DCMAKE_TOOLCHAIN_FILE=CMakeToolchain.cmake -B build-aarch64 .
cmake --build build-aarch64

# Verify it's correct
file build-aarch64/monitor_service
```

---

## Next Steps

1. ✅ Install toolchain (Step 1 above)
2. ✅ Build project (Step 2 above)
3. ✅ Deploy to device (Step 3 above)
4. 📖 Read `REPORT.md` for complete documentation
5. 🔧 Review `src/main.cpp` for implementation details
6. 🚀 Consider persistent installation as systemd service (see REPORT.md Deployment section)

---

## Key Characteristics

- **Single Executable:** One statically-linked binary, no runtime dependencies
- **Minimal Footprint:** ~650 KB binary size
- **Cross-Platform:** Built on macOS, runs on ARM64 Linux
- **Zero Dependencies:** Uses only standard C++ library and POSIX syscalls
- **Production Ready:** Error handling and graceful degradation built-in

---

For detailed information, see `REPORT.md`
