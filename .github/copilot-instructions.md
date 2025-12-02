# AI Coding Agent Instructions - Box_Flasher

## Project Overview
**Dual-purpose project**: (1) C++17 monitoring service for Amlogic S905W devices, and (2) Shell-based image flashing/device setup workflow.

**Key Facts:**
- **Build hosts:** macOS (Apple Silicon), Linux, Windows (Git Bash/MinGW)
- **Target:** aarch64 (ARMv8) embedded Linux (Armbian/CoreELEC on S905W)
- **C++ binary:** Static-linked, zero runtime dependencies, reads `/sys`/`/proc` directly
- **Shell scripts:** Device flashing, image download, service deployment

## Two Main Workflows

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

**⚠️ USB A-to-A Direct Flashing** (NOT SD card/USB drive):
This project flashes directly to the S905W's internal eMMC via USB A-to-A cable using Amlogic's maskrom/burn mode. The device must be put into USB flashing mode (boot button or NAND_BOOT jumper) and connected via USB A male-to-male cable.

**Cross-platform flashing tools:**
- **macOS:** `usb_flash_s905w.sh` uses `aml_usb_flashing_tool` (Homebrew: `messense/amlogic-tools`)
- **Windows:** Official [Amlogic USB Burning Tool](https://github.com/nicknumb/amlogic_usb_burn_tool) (GUI, most reliable)
- **Linux:** `aml_usb_flashing_tool` or `pyamlboot` for direct USB flashing

## Critical Architecture: Cross-Compilation

Architecture-specific flags belong in `CMakeToolchain.cmake`, NOT `CMakeLists.txt`. The toolchain auto-detects compiler triple:
- `aarch64-unknown-linux-gnu` (Homebrew messense tap - macOS)
- `aarch64-linux-gnu` (apt - Linux/WSL)
- `aarch64-none-linux-gnu` (Arm GNU Toolchain - Windows)

**Toolchain installation:**
```bash
# macOS
brew tap messense/macos-cross-toolchains && brew install messense/macos-cross-toolchains/aarch64-unknown-linux-gnu
# Linux/WSL
sudo apt-get install g++-aarch64-linux-gnu
# Windows: Install Arm GNU Toolchain 14.3.Rel1, add to PATH
```

## Configuration System

All scripts load config via `scripts/load_config.sh` which sources:
- `data/config/device.config` - S905W hardware paths (`THERMAL_ZONE_PATH`, `MEMINFO_PATH`)
- `data/config/build.config` - Compiler flags, build dir (`BUILD_DIR=build-aarch64`)
- `data/config/flashing.config` - Image URLs, filenames
- `data/config/service.config` - Service installation paths
- `data/.env` - Local overrides (highest precedence, gitignored)

**Pattern:** Scripts source `load_config.sh` at startup, then use exported variables with fallback defaults:
```bash
if [ -f "./scripts/load_config.sh" ]; then source ./scripts/load_config.sh; fi
EXECUTABLE_PATH="${EXECUTABLE_PATH:-${BUILD_DIR:-build-aarch64}/monitor_service}"
```

## C++ Code Patterns

### Graceful Degradation (src/main.cpp)
Return sentinel values on failure, caller gates output:

```cpp
double get_cpu_temp() {
    std::ifstream file("/sys/class/thermal/thermal_zone0/temp");
    if (!file.is_open()) { return -1.0; }  // Sentinel
    // ...parse millidegrees → Celsius
}
// Caller:
double temp = get_cpu_temp();
if (temp >= 0) { std::cout << temp << " °C"; }  // Gate on success
```

**Three monitoring functions:**
- `get_cpu_temp()` → Returns `-1.0` on failure (parses `/sys/class/thermal/thermal_zone0/temp`)
- `get_ram_usage()` → Returns zero-struct on failure (parses `/proc/meminfo`)
- `get_storage_health()` → Prints directly, filters pseudo-fs (tmpfs, sysfs, proc, cgroup, devtmpfs, devpts)

**Rules:** No `system()` calls, no shell dependencies. Read only from `/sys`, `/proc`, `/dev`.

### Header Pattern (include/monitor.h)
The header declares testable parse functions (`parse_cpu_temp_string`, `parse_meminfo_string`) separate from file I/O. When adding new sensors, follow this pattern:
- **Parse function:** Takes string input, returns parsed result (unit-testable)
- **Wrapper function:** Reads file, calls parse function (integration)

### CMakeLists.txt Conventions
- Static linking via `target_link_options()`, NOT `CMAKE_CXX_FLAGS`
- Architecture flags (`-march=armv8-a`) conditional on `CMAKE_SYSTEM_PROCESSOR == aarch64`
- Single target: `add_executable(monitor_service src/main.cpp)`

## Test Scripts

| Script | Purpose | When to Run |
|--------|---------|-------------|
| `tests/test.sh` | 7-step build verification | After any C++/CMake change |
| `tests/deployment_test.sh` | SCP + SSH remote execution | After successful build |
| `tests/setup_toolchain.sh` | Install cross-compiler | One-time setup |

**Verification command:**
```bash
./tests/test.sh  # Runs: CMake check → compiler check → build → architecture verify
```

## Common Mistakes

1. **Missing toolchain file** - Always use `-DCMAKE_TOOLCHAIN_FILE=CMakeToolchain.cmake`
2. **Wrong architecture flags location** - Put in `CMakeToolchain.cmake`, not `CMakeLists.txt`
3. **Dynamic linking** - If `file` output doesn't show "statically linked", rebuild
4. **Testing locally** - Binary only runs on aarch64 Linux, not macOS/Windows
5. **Adding external dependencies** - Forbidden; use only C++17 stdlib + POSIX

## File Reference

| File | Responsibility |
|------|----------------|
| `src/main.cpp` | Monitoring logic (add sensors here) |
| `CMakeToolchain.cmake` | Cross-compiler paths, target system |
| `CMakeLists.txt` | Build config (don't add arch flags) |
| `scripts/load_config.sh` | Config loader for all shell scripts |
| `data/config/*.config` | Device, build, flash, service settings |
| `setup_device.sh` | One-command device deployment |

**⚠️ Image URL Versioning:** `data/config/flashing.config` contains a pinned Armbian release URL (`Armbian_25.11.0_amlogic_s905w_bullseye_6.1.158`). Update `IMAGE_SOURCE_URL`, `IMAGE_FILENAME`, and `IMAGE_COMPRESSED_FILENAME` when newer S905W releases are needed.

- **CMake Toolchain Docs:** https://cmake.org/cmake/help/latest/manual/cmake-toolchains.7.html
- **Cross-compiler detection fallback:** Both `aarch64-*` triples handled in `CMakeToolchain.cmake` lines 15-30
- **REPORT.md:** Complete phase-by-phase documentation if architectural decisions need explanation
- **QUICKSTART.md:** Fastest path to verification if build fails
