#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <cstdlib>
#include <iomanip>

/**
 * Reads and parses CPU temperature from /sys/class/thermal/thermal_zone0/temp
 * Returns temperature in Celsius
 */
double get_cpu_temp() {
    std::ifstream temp_file("/sys/class/thermal/thermal_zone0/temp");
    
    if (!temp_file.is_open()) {
        std::cerr << "Warning: Cannot open thermal zone file. Skipping CPU temperature." << std::endl;
        return -1.0;
    }
    
    std::string temp_str;
    if (std::getline(temp_file, temp_str)) {
        try {
            // Temperature is typically in millidegrees Celsius
            long temp_millidegrees = std::stol(temp_str);
            double temp_celsius = temp_millidegrees / 1000.0;
            return temp_celsius;
        } catch (const std::exception& e) {
            std::cerr << "Error parsing temperature: " << e.what() << std::endl;
            return -1.0;
        }
    }
    
    return -1.0;
}

/**
 * Structure to hold RAM usage information
 */
struct MemoryInfo {
    long total_kb;
    long free_kb;
    long available_kb;
    long used_kb;
};

/**
 * Reads and parses /proc/meminfo to calculate RAM usage
 * Returns memory information in kilobytes
 */
MemoryInfo get_ram_usage() {
    MemoryInfo mem_info = {0, 0, 0, 0};
    
    std::ifstream meminfo_file("/proc/meminfo");
    
    if (!meminfo_file.is_open()) {
        std::cerr << "Warning: Cannot open /proc/meminfo. Skipping RAM usage." << std::endl;
        return mem_info;
    }
    
    std::string line;
    while (std::getline(meminfo_file, line)) {
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

/**
 * Reads storage information from /proc/mounts and df-like statistics
 * Returns basic storage health info
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
                fstype != "devtmpfs" && fstype != "devpts" && fstype != "cgroup") {
                mount_points.push_back(mount_point);
            }
        }
    }
    
    std::cout << "Mounted filesystems (storage points):" << std::endl;
    for (const auto& mp : mount_points) {
        std::cout << "  - " << mp << std::endl;
    }
}

/**
 * Main function: Gather and display system metrics
 */
int main() {
    std::cout << "=== System Monitoring Service ===" << std::endl;
    std::cout << "Target: Amlogic S905W Embedded Linux" << std::endl;
    std::cout << std::endl;
    
    // CPU Temperature
    std::cout << "CPU Temperature:" << std::endl;
    double cpu_temp = get_cpu_temp();
    if (cpu_temp >= 0) {
        std::cout << "  Temperature: " << std::fixed << std::setprecision(2) 
                  << cpu_temp << " °C" << std::endl;
    } else {
        std::cout << "  Temperature: Unavailable" << std::endl;
    }
    std::cout << std::endl;
    
    // RAM Usage
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
    
    // Storage Health
    std::cout << "Storage Information:" << std::endl;
    get_storage_health();
    std::cout << std::endl;
    
    std::cout << "=== Monitoring Service Completed ===" << std::endl;
    
    return 0;
}
