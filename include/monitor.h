#pragma once

#include <string>

struct MemoryInfo {
    long total_kb;
    long free_kb;
    long available_kb;
    long used_kb;
};

// Parse functions (unit-testable)
// parse_cpu_temp_string: given the full file content of /sys/class/thermal/thermal_zone0/temp
//                      returns temperature in Celsius (-1.0 if parse fails)
double parse_cpu_temp_string(const std::string& input);

// parse_meminfo_string: given the full content of /proc/meminfo
//                       returns MemoryInfo struct (zeros on parse failure)
MemoryInfo parse_meminfo_string(const std::string& input);

// High-level wrappers that read from default paths
double get_cpu_temp();
MemoryInfo get_ram_usage();

// Storage health remains untested for now, so keep as a helper
void get_storage_health();
