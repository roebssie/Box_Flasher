/**
 * @file test.cpp
 * @brief Unit tests for the monitoring service parse functions
 * 
 * These tests verify the parse functions work correctly without file I/O.
 * This file can be compiled and run on the build host (not just target).
 * 
 * Build for host testing:
 *   g++ -std=c++17 -o test_runner tests/test.cpp src/main.cpp -DUNIT_TEST_MODE
 * 
 * The tests use simple assertions rather than a testing framework
 * to maintain zero external dependencies.
 */

#include "../include/monitor.h"
#include <iostream>
#include <cassert>
#include <cmath>
#include <string>

// Simple test framework macros
#define TEST_CASE(name) void test_##name()
#define RUN_TEST(name) do { \
    std::cout << "Running: " << #name << "... "; \
    test_##name(); \
    std::cout << "PASSED" << std::endl; \
} while(0)

#define ASSERT_EQ(expected, actual) do { \
    if ((expected) != (actual)) { \
        std::cerr << "FAILED: expected " << (expected) << " but got " << (actual) << std::endl; \
        assert(false); \
    } \
} while(0)

#define ASSERT_NEAR(expected, actual, tolerance) do { \
    if (std::abs((expected) - (actual)) > (tolerance)) { \
        std::cerr << "FAILED: expected ~" << (expected) << " but got " << (actual) << std::endl; \
        assert(false); \
    } \
} while(0)

// ============================================================================
// CPU Temperature Parse Tests
// ============================================================================

TEST_CASE(parse_cpu_temp_normal) {
    // Normal case: 45000 millidegrees = 45.0 Celsius
    double result = parse_cpu_temp_string("45000");
    ASSERT_NEAR(45.0, result, 0.001);
}

TEST_CASE(parse_cpu_temp_with_newline) {
    // Input with trailing newline (common from file read)
    double result = parse_cpu_temp_string("45000\n");
    ASSERT_NEAR(45.0, result, 0.001);
}

TEST_CASE(parse_cpu_temp_high_temp) {
    // High temperature: 85500 millidegrees = 85.5 Celsius
    double result = parse_cpu_temp_string("85500");
    ASSERT_NEAR(85.5, result, 0.001);
}

TEST_CASE(parse_cpu_temp_low_temp) {
    // Low temperature: 25000 millidegrees = 25.0 Celsius
    double result = parse_cpu_temp_string("25000");
    ASSERT_NEAR(25.0, result, 0.001);
}

TEST_CASE(parse_cpu_temp_empty_string) {
    // Empty string should return sentinel -1.0
    double result = parse_cpu_temp_string("");
    ASSERT_NEAR(-1.0, result, 0.001);
}

TEST_CASE(parse_cpu_temp_invalid_string) {
    // Non-numeric string should return sentinel -1.0
    double result = parse_cpu_temp_string("invalid");
    ASSERT_NEAR(-1.0, result, 0.001);
}

TEST_CASE(parse_cpu_temp_zero) {
    // Zero temperature (unlikely but valid)
    double result = parse_cpu_temp_string("0");
    ASSERT_NEAR(0.0, result, 0.001);
}

// ============================================================================
// Memory Info Parse Tests
// ============================================================================

TEST_CASE(parse_meminfo_normal) {
    // Typical /proc/meminfo content
    std::string meminfo = 
        "MemTotal:        2048000 kB\n"
        "MemFree:          512000 kB\n"
        "MemAvailable:     768000 kB\n"
        "Buffers:           64000 kB\n"
        "Cached:           256000 kB\n";
    
    MemoryInfo result = parse_meminfo_string(meminfo);
    
    ASSERT_EQ(2048000, result.total_kb);
    ASSERT_EQ(512000, result.free_kb);
    ASSERT_EQ(768000, result.available_kb);
    ASSERT_EQ(2048000 - 768000, result.used_kb);  // Used = Total - Available
}

TEST_CASE(parse_meminfo_no_available) {
    // Older kernels might not have MemAvailable
    std::string meminfo = 
        "MemTotal:        2048000 kB\n"
        "MemFree:          512000 kB\n"
        "Buffers:           64000 kB\n";
    
    MemoryInfo result = parse_meminfo_string(meminfo);
    
    ASSERT_EQ(2048000, result.total_kb);
    ASSERT_EQ(512000, result.free_kb);
    ASSERT_EQ(0, result.available_kb);
    ASSERT_EQ(2048000 - 512000, result.used_kb);  // Falls back to Total - Free
}

TEST_CASE(parse_meminfo_empty_string) {
    // Empty string should return zero-struct
    MemoryInfo result = parse_meminfo_string("");
    
    ASSERT_EQ(0, result.total_kb);
    ASSERT_EQ(0, result.free_kb);
    ASSERT_EQ(0, result.available_kb);
    ASSERT_EQ(0, result.used_kb);
}

TEST_CASE(parse_meminfo_malformed) {
    // Malformed content should still parse what it can
    std::string meminfo = 
        "MemTotal:        1024000 kB\n"
        "InvalidLine without proper format\n"
        "MemFree: kB\n";  // Missing value
    
    MemoryInfo result = parse_meminfo_string(meminfo);
    
    ASSERT_EQ(1024000, result.total_kb);
    ASSERT_EQ(0, result.free_kb);  // Failed to parse
}

TEST_CASE(parse_meminfo_s905w_realistic) {
    // Realistic S905W device with ~1GB RAM
    std::string meminfo = 
        "MemTotal:        1017292 kB\n"
        "MemFree:          654320 kB\n"
        "MemAvailable:     802468 kB\n"
        "Buffers:           18432 kB\n"
        "Cached:           147716 kB\n"
        "SwapCached:            0 kB\n"
        "Active:           156048 kB\n"
        "Inactive:          98560 kB\n";
    
    MemoryInfo result = parse_meminfo_string(meminfo);
    
    ASSERT_EQ(1017292, result.total_kb);
    ASSERT_EQ(654320, result.free_kb);
    ASSERT_EQ(802468, result.available_kb);
    ASSERT_EQ(1017292 - 802468, result.used_kb);
}

// ============================================================================
// Main Test Runner
// ============================================================================

int main() {
    std::cout << "=== Monitor Service Unit Tests ===" << std::endl;
    std::cout << std::endl;
    
    std::cout << "--- CPU Temperature Parse Tests ---" << std::endl;
    RUN_TEST(parse_cpu_temp_normal);
    RUN_TEST(parse_cpu_temp_with_newline);
    RUN_TEST(parse_cpu_temp_high_temp);
    RUN_TEST(parse_cpu_temp_low_temp);
    RUN_TEST(parse_cpu_temp_empty_string);
    RUN_TEST(parse_cpu_temp_invalid_string);
    RUN_TEST(parse_cpu_temp_zero);
    
    std::cout << std::endl;
    std::cout << "--- Memory Info Parse Tests ---" << std::endl;
    RUN_TEST(parse_meminfo_normal);
    RUN_TEST(parse_meminfo_no_available);
    RUN_TEST(parse_meminfo_empty_string);
    RUN_TEST(parse_meminfo_malformed);
    RUN_TEST(parse_meminfo_s905w_realistic);
    
    std::cout << std::endl;
    std::cout << "=== All Tests Passed! ===" << std::endl;
    
    return 0;
}
