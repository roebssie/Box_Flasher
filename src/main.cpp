/**
 * @file main.cpp
 * @brief System Monitoring Service for Amlogic S905W Embedded Linux
 * 
 * This service monitors CPU temperature, RAM usage, and storage health
 * by reading directly from /sys and /proc filesystems.
 * 
 * Architecture notes:
 * - Statically linked with zero runtime dependencies
 * - No system() calls or shell dependencies
 * - Graceful degradation: returns sentinel values on failure
 * - Parse functions are separate from I/O for testability
 */

#include "../include/monitor.h"
#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <cstdlib>
#include <iomanip>

// ============================================================================
// Parse Functions (Unit-Testable)
// These functions take string input and return parsed results.
// ============================================================================

/**
 * @brief Parse CPU temperature from thermal zone file content
 * 
 * @param input Raw string content (typically millidegrees Celsius)
 * @return Temperature in Celsius, or -1.0 on failure (sentinel value)
 */
double parse_cpu_temp_string(const std::string& input) {
    if (input.empty()) {
        return -1.0;
    }
    
    try {
        // Temperature is typically in millidegrees Celsius
        long temp_millidegrees = std::stol(input);
        double temp_celsius = temp_millidegrees / 1000.0;
        return temp_celsius;
    } catch (const std::exception& e) {
        return -1.0;
    }
}

/**
 * @brief Parse memory information from /proc/meminfo content
 * 
 * @param input Raw string content from /proc/meminfo
 * @return MemoryInfo struct with parsed values, or zero-struct on failure
 */
MemoryInfo parse_meminfo_string(const std::string& input) {
    MemoryInfo mem_info = {0, 0, 0, 0};
    
    if (input.empty()) {
        return mem_info;
    }
    
    std::istringstream stream(input);
    std::string line;
    
    while (std::getline(stream, line)) {
        std::istringstream iss(line);
        std::string key;
        long value;
        std::string unit;
        
        if (iss >> key >> value >> unit) {
            if (key == "MemTotal:") {
                mem_info.total_kb = value;
            } else if (key == "MemFree:") {
                mem_info.free_kb = value;
            } else if (key == "MemAvailable:") {
                mem_info.available_kb = value;
            }
        }
    }
    
    // Calculate used memory
    if (mem_info.available_kb > 0) {
        mem_info.used_kb = mem_info.total_kb - mem_info.available_kb;
    } else if (mem_info.free_kb > 0) {
        mem_info.used_kb = mem_info.total_kb - mem_info.free_kb;
    }
    
    return mem_info;
}

// ============================================================================
// High-Level Wrapper Functions (Integration)
// These functions handle file I/O and call the parse functions.
// ============================================================================

/**
 * Reads and parses CPU temperature from /sys/class/thermal/thermal_zone0/temp
 * Returns temperature in Celsius, or -1.0 on failure (sentinel value)
 */
double get_cpu_temp() {
    std::ifstream temp_file("/sys/class/thermal/thermal_zone0/temp");
    
    if (!temp_file.is_open()) {
        std::cerr << "Warning: Cannot open thermal zone file. Skipping CPU temperature." << std::endl;
        return -1.0;
    }
    
    std::string temp_str;
    if (std::getline(temp_file, temp_str)) {
        double result = parse_cpu_temp_string(temp_str);
        if (result < 0) {
            std::cerr << "Error parsing temperature" << std::endl;
        }
        return result;
    }
    
    return -1.0;
}

/**
 * Reads and parses /proc/meminfo to calculate RAM usage
 * Returns memory information in kilobytes, or zero-struct on failure
 */
MemoryInfo get_ram_usage() {
    std::ifstream meminfo_file("/proc/meminfo");
    
    if (!meminfo_file.is_open()) {
        std::cerr << "Warning: Cannot open /proc/meminfo. Skipping RAM usage." << std::endl;
        return MemoryInfo{0, 0, 0, 0};
    }
    
    std::ostringstream content;
    content << meminfo_file.rdbuf();
    
    return parse_meminfo_string(content.str());
}

/**
 * Reads storage information from /proc/mounts and displays mount points
 * Filters out pseudo-filesystems: tmpfs, sysfs, proc, cgroup, cgroup2, devtmpfs, devpts
 */
void get_storage_health() {
    std::ifstream mounts_file("/proc/mounts");
    
    if (!mounts_file.is_open()) {
        std::cerr << "Warning: Cannot open /proc/mounts. Skipping storage info." << std::endl;
        return;
    }
    
    std::string line;
    std::vector<std::string> mount_points;
    
    while (std::getline(mounts_file, line)) {
        std::istringstream iss(line);
        std::string device, mount_point, fstype;
        
        if (iss >> device >> mount_point >> fstype) {
            // Filter out pseudo filesystems
            if (fstype != "tmpfs" && fstype != "sysfs" && fstype != "proc" && 
                fstype != "devtmpfs" && fstype != "devpts" && 
                fstype != "cgroup" && fstype != "cgroup2") {
                mount_points.push_back(mount_point);
            }
        }
    }
    
    std::cout << "Mounted filesystems (storage points):" << std::endl;
    for (const auto& mp : mount_points) {
        std::cout << "  - " << mp << std::endl;
    }
}

// ============================================================================
// Main Entry Point
// ============================================================================

/**
 * Main function: Gather and display system metrics
 * Demonstrates graceful degradation - each metric is gated on success
 */
int main() {
    std::cout << "=== System Monitoring Service ===" << std::endl;
    std::cout << "Target: Amlogic S905W Embedded Linux" << std::endl;
    std::cout << std::endl;
    
    // CPU Temperature - gate output on success (temp >= 0)
    std::cout << "CPU Temperature:" << std::endl;
    double cpu_temp = get_cpu_temp();
    if (cpu_temp >= 0) {
        std::cout << "  Temperature: " << std::fixed << std::setprecision(2) 
                  << cpu_temp << " °C" << std::endl;
    } else {
        std::cout << "  Temperature: Unavailable" << std::endl;
    }
    std::cout << std::endl;
    
    // RAM Usage - gate output on success (total_kb > 0)
    std::cout << "RAM Usage:" << std::endl;
    MemoryInfo mem = get_ram_usage();
    if (mem.total_kb > 0) {
        double total_mb = mem.total_kb / 1024.0;
        double free_mb = mem.free_kb / 1024.0;
        double available_mb = mem.available_kb / 1024.0;
        double used_mb = mem.used_kb / 1024.0;
        double usage_percent = (used_mb / total_mb) * 100.0;
        
        std::cout << "  Total:     " << std::fixed << std::setprecision(2) 
                  << total_mb << " MB" << std::endl;
        std::cout << "  Free:      " << std::fixed << std::setprecision(2) 
                  << free_mb << " MB" << std::endl;
        std::cout << "  Available: " << std::fixed << std::setprecision(2) 
                  << available_mb << " MB" << std::endl;
        std::cout << "  Used:      " << std::fixed << std::setprecision(2) 
                  << used_mb << " MB (" << usage_percent << "%)" << std::endl;
    } else {
        std::cout << "  RAM info: Unavailable" << std::endl;
    }
    std::cout << std::endl;
    
    // Storage Health - prints directly
    std::cout << "Storage Information:" << std::endl;
    get_storage_health();
    std::cout << std::endl;
    
    std::cout << "=== Monitoring Service Completed ===" << std::endl;
    
    return 0;
}
