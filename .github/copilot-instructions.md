# AI Coding Agent Instructions - Embedded System Monitoring Service

## Project Overview
**Cross-platform embedded monitoring service**: Apple Silicon macOS / linux / x64 windows (WSL2) → aarch64 Linux cross-compilation workflow. Single C++17 executable monitoring CPU temperature, RAM usage, and storage on Amlogic S905W devices (Armbian/Ophub).

**Key Facts:**
- **Host build platform:** Apple Silicon (arm64) macOS and x64 Linux and x64 windows (WSL2)
- **Target architecture:** aarch64 (ARMv8) embedded Linux  
- **Executable characteristics:** Single static binary (~5-8 MB), zero runtime dependencies
- **Language:** C++17 with POSIX syscalls for file I/O

## Critical Architecture Pattern: Cross-Compilation Pipeline

The project's core concept is **host-to-target architecture mismatch**:
- **Build Host:** Apple Silicon (arm64) macOS and x64 Linux and x64 windows (WSL2)
- **Build Output:** aarch64 ELF binary
- **Target Platform:** Minimal embedded Linux (Amlogic S905W, Armbian/Ophub)

**Key implication:** Never assume compilation flags work universally. Architecture-specific flags MUST be in `CMakeToolchain.cmake`, not `CMakeLists.txt`. The toolchain file is the single source of truth for cross-compiler paths and target system settings.

### CMakeToolchain.cmake Triple-Naming Support
The toolchain auto-detects both naming conventions (lines 15-30):
- `aarch64-unknown-linux-gnu` (Homebrew messense tap - **preferred**)
- `aarch64-linux-gnu` (traditional GNU - fallback)

Installation command (tested stable):
```bash
brew tap messense/macos-cross-toolchains
brew install messense/macos-cross-toolchains/aarch64-unknown-linux-gnu
```

**If toolchain installation fails:** Check `/opt/homebrew/bin/` and `/usr/local/bin/` for either triple name. If neither exists, run `./tests/setup_toolchain.sh` for installation diagnostics.

## Build Workflow (Exact Command Sequence)

```bash
# Step 1: Verify toolchain (one-time check)
aarch64-unknown-linux-gnu-g++ --version  # or aarch64-linux-gnu-g++ if above fails

# Step 2: Run verification suite
./tests/test.sh  # Comprehensive 7-step verification

# Step 3: Configure with toolchain
cmake -DCMAKE_TOOLCHAIN_FILE=CMakeToolchain.cmake -B build-aarch64 .

# Step 4: Build
cmake --build build-aarch64

# Step 5: Verify (CRITICAL - test before deployment)
file build-aarch64/monitor_service  # Must show: ARM aarch64, statically linked
```

**Diagnostic Tips:**
- If CMake shows "unused `CMAKE_TOOLCHAIN_FILE`" warning → toolchain detection failed silently. Run `./tests/test.sh` to diagnose compiler availability.
- If build fails with "cannot find -lstdc++" → linking flags in CMakeLists.txt are wrong. Verify `target_link_options()` includes `-static-libstdc++`.
- If executable is dynamically linked → binary is undeployable to minimal embedded Linux. Rebuild with toolchain file specified.

## Code Organization & Patterns

### src/main.cpp: System Monitoring Functions
Three independent monitoring functions with **graceful degradation pattern**:

1. **`get_cpu_temp()`** - Parses `/sys/class/thermal/thermal_zone0/temp` (millidegrees → Celsius)
   - Returns `-1.0` on failure, caller handles output formatting
   - Exception handling wraps `std::stol()` parsing
   - Example: `if (cpu_temp >= 0)` in main() gates optional output

2. **`get_ram_usage()`** - Parses `/proc/meminfo`, prefers MemAvailable over MemFree
   - Returns zero-initialized struct on failure (not exception)
   - Memory calculation: Used = Total - Available (accounts for cached memory)
   - Falls back to MemFree if MemAvailable not present
   - Example: `if (mem_info.total_kb > 0)` guards formatting in caller

3. **`get_storage_health()`** - Lists filesystems, filters pseudo-fs (tmpfs, sysfs, proc, cgroup, devtmpfs, devpts)
   - No return value; prints directly to stdout
   - Pattern: Parse `/proc/mounts` line-by-line with `istringstream`, split by whitespace
   - Pseudo-filesystem detection: compare `fstype` field against hardcoded filter list
   - Example: `if (fstype != "tmpfs" && fstype != "sysfs" ...)` ensures real FS only

**Convention:** Avoid exceptions for file I/O failures; return sentinel values (-1.0, zero struct). The `main()` function has optional field formatting based on success/failure. This enables graceful degradation when system files are unavailable.

### CMakeLists.txt: Minimal Configuration
- **Single target:** `add_executable(monitor_service src/main.cpp)`
- **C++17 enforcement:** Non-negotiable for std::stol(), structured bindings potential
- **Static library linking:** `-static-libgcc -static-libstdc++` in `target_link_options()`, NOT compiler flags
- **Architecture flags:** `-march=armv8-a` applied conditionally only if `CMAKE_SYSTEM_PROCESSOR` == `aarch64` (lines 37-41)

**When modifying:** 
- Don't add optimization flags to CMakeLists.txt; the cross-toolchain defines `-O2` baseline.
- Static linking flags belong in `target_link_options()` (applied only to this target), not `CMAKE_CXX_FLAGS` (global).
- Conditional architecture flags prevent errors when CMake runs on macOS host during configuration.

### Adding New Monitoring Functions
**Template for new sensors:**
```cpp
// Returns -1.0 or zero struct on file not found
SensorType get_sensor_data() {
    std::ifstream file("/sys/path/to/sensor");
    if (!file.is_open()) {
        std::cerr << "Warning: Cannot open sensor file." << std::endl;
        return SENTINEL_VALUE;  // -1.0 or zero struct
    }
    // Parse and return result
    return result;
}

// In main(), gate output on success:
SensorType data = get_sensor_data();
if (data != SENTINEL_VALUE) {
    std::cout << "Sensor: " << data << std::endl;
}
```
**Rules:** No system() calls, no external tools, no shell dependencies. Read only from `/sys`, `/proc`, or `/dev`.

## Deployment Automation

### deployment_test.sh Validation Sequence
Located in `tests/deployment_test.sh` (139 lines). Run after `./tests/test.sh` succeeds.

Validation steps:
1. Verify executable exists at `./build-aarch64/monitor_service`
2. Check file type with `file` command (must contain "aarch64")
3. Validate SSH connectivity: `ssh -o ConnectTimeout=5 $TARGET_HOST`
4. Transfer via SCP: `scp -P $TARGET_PORT build-aarch64/monitor_service $TARGET_HOST:/tmp/`
5. Execute remotely and parse output
6. Verify output contains expected sections (CPU, RAM, Storage)

**Environment variables:** Always export before running:
```bash
export TARGET_HOST=root@192.168.1.100
export TARGET_PORT=22
./tests/deployment_test.sh
```

### test.sh: Comprehensive Verification
Located in `tests/test.sh` (185 lines). Run after every code or CMake change.

Runs 7 sequential checks with colored output:
1. CMake availability
2. Cross-compiler availability (tries `aarch64-unknown-linux-gnu-g++` first, then `aarch64-linux-gnu-g++`)
3. Project files exist (src/main.cpp, CMakeLists.txt, CMakeToolchain.cmake)
4. Cross-compilation test on temporary C++ file (verifies toolchain + linking flags)
5. CMake configuration run
6. Full build execution
7. Executable architecture + linking verification (file, size, dependencies check)

**Usage:** `./tests/test.sh` from project root. **CRITICAL:** Run before any deployment; stops on first failure with diagnostic output.

## Dependency Strategy: Zero External Runtime

**Non-negotiable constraint:** The executable must run on minimal embedded Linux without package installation.

- ✅ **Allowed:** C++17 standard library, POSIX syscalls (fopen, getline, etc.)
- ❌ **Forbidden:** Qt, GLib, Boost, custom dependencies
- **Linking:** `libc.so.6` only (verified with `objdump -p | grep NEEDED`)

**If adding new monitoring functions:** Read from `/sys`, `/proc`, or `/dev` directly. No system() calls to shell commands.

## File Locations & Responsibilities

| File | Responsibility | When to Modify |
|------|-----------------|-----------------|
| `src/main.cpp` | Monitoring logic | Add sensors, adjust output format |
| `CMakeLists.txt` | Build configuration | Change C++ standard, add compile flags |
| `CMakeToolchain.cmake` | Cross-compiler + target system | Update toolchain paths if Homebrew changes |
| `.github/copilot-instructions.md` | AI agent knowledge | Update build steps if workflow changes |
| `tests/test.sh` | Build verification | Sync with new test requirements |
| `tests/deployment_test.sh` | Remote deployment | Modify for different SSH host/port handling |
| `reports/REPORT.md` | Technical documentation | Reflect changes in architectural sections |
| `reports/QUICKSTART.md` | Fast deployment reference | Keep step-by-step instructions aligned |

## Common AI Agent Mistakes to Avoid

1. **Confusing toolchain triple names** - Always check both `aarch64-unknown-linux-gnu` and `aarch64-linux-gnu` paths
2. **Adding dependencies to CMakeLists.txt** - Static library flags go in `target_link_options()`, not `set(CMAKE_CXX_FLAGS ...)`
3. **Testing on macOS instead of target** - The binary runs on embedded Linux only; macOS cannot execute aarch64-linux ELF files
4. **Forgetting CMAKE_TOOLCHAIN_FILE** - CMake must be invoked with `-DCMAKE_TOOLCHAIN_FILE=CMakeToolchain.cmake`
5. **Modifying exception handling to use exceptions** - Keep sentinel return values for graceful degradation on embedded systems
6. **Adding pseudo-filesystem types to mount_points** - Storage function must filter tmpfs, sysfs, proc, cgroup, devtmpfs, devpts
7. **Reading sensor files synchronously in main()** - Current design is single-threaded; design for embedded constraints (limited CPU, memory)

## Build Verification Checklist

Before committing changes to any C++ or CMake files:
1. Run `./test.sh` - verifies entire pipeline
2. Check `file build-aarch64/monitor_service` output contains "aarch64"
3. Inspect `objdump -p build-aarch64/monitor_service | grep NEEDED` - should only list `libc.so.6`
4. Run `du -h build-aarch64/monitor_service` - should be < 10 MB (typically 5-6 MB with debug symbols)

## Device Integration Pattern

Target device expects:
- Executable path: `/tmp/monitor_service` (via SCP deployment)
- Working directory: Any (uses absolute paths `/sys`, `/proc`)
- No configuration files needed
- Output: stdout (human-readable)

Optional systemd integration documented in `REPORT.md` Deployment section.

## Key Resources

- **CMake Toolchain Docs:** https://cmake.org/cmake/help/latest/manual/cmake-toolchains.7.html
- **Cross-compiler detection fallback:** Both `aarch64-*` triples handled in `CMakeToolchain.cmake` lines 15-30
- **REPORT.md:** Complete phase-by-phase documentation if architectural decisions need explanation
- **QUICKSTART.md:** Fastest path to verification if build fails
