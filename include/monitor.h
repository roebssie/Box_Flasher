#pragma once

/**
 * @file monitor.h
 * @brief System monitoring functions for Amlogic S905W embedded Linux devices
 * 
 * This header declares testable parse functions separate from file I/O,
 * following the pattern described in the project architecture:
 * - Parse functions: Take string input, return parsed result (unit-testable)
 * - Wrapper functions: Read file, call parse function (integration)
 * 
 * Rules: No system() calls, no shell dependencies. Read only from /sys, /proc, /dev.
 */

#include <string>

/**
 * @brief Structure to hold RAM usage information
 * All values in kilobytes (KB)
 */
struct MemoryInfo {
    long total_kb;      ///< Total physical RAM
    long free_kb;       ///< Completely unused RAM
    long available_kb;  ///< Available RAM for new allocations (includes reclaimable)
    long used_kb;       ///< RAM in active use (total - available)
};

// ============================================================================
// Parse Functions (Unit-Testable)
// These functions take string input and return parsed results.
// They contain no file I/O and can be unit tested independently.
// ============================================================================

/**
 * @brief Parse CPU temperature from string content
 * 
 * Parses the content of /sys/class/thermal/thermal_zone0/temp
 * which contains temperature in millidegrees Celsius.
 * 
 * @param input Raw string content from thermal zone file
 * @return Temperature in Celsius, or -1.0 on parse failure (sentinel value)
 * 
 * @example
 *   double temp = parse_cpu_temp_string("45000\n");
 *   // Returns 45.0 (degrees Celsius)
 */
double parse_cpu_temp_string(const std::string& input);

/**
 * @brief Parse memory information from string content
 * 
 * Parses the content of /proc/meminfo to extract memory statistics.
 * Looks for MemTotal, MemFree, and MemAvailable keys.
 * 
 * @param input Raw string content from /proc/meminfo
 * @return MemoryInfo struct with parsed values, or zero-struct on failure
 * 
 * @example
 *   std::string meminfo = "MemTotal: 2048000 kB\nMemFree: 512000 kB\n...";
 *   MemoryInfo mem = parse_meminfo_string(meminfo);
 */
MemoryInfo parse_meminfo_string(const std::string& input);

// ============================================================================
// High-Level Wrapper Functions (Integration)
// These functions handle file I/O and call the parse functions.
// ============================================================================

/**
 * @brief Read and parse CPU temperature from thermal zone
 * 
 * Reads from /sys/class/thermal/thermal_zone0/temp and parses result.
 * Returns sentinel value -1.0 if file cannot be opened or parsed.
 * Caller should gate output on success: if (temp >= 0) { ... }
 * 
 * @return Temperature in Celsius, or -1.0 on failure
 */
double get_cpu_temp();

/**
 * @brief Read and parse RAM usage from /proc/meminfo
 * 
 * Returns zero-struct on failure. Caller should check total_kb > 0.
 * 
 * @return MemoryInfo struct with memory statistics
 */
MemoryInfo get_ram_usage();

/**
 * @brief Display storage health information
 * 
 * Reads /proc/mounts and prints mount points, filtering out pseudo-filesystems:
 * tmpfs, sysfs, proc, cgroup, cgroup2, devtmpfs, devpts
 * 
 * This function prints directly to stdout rather than returning a value.
 */
void get_storage_health();
