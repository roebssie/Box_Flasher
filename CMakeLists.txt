cmake_minimum_required(VERSION 3.10)

# Project name and version
project(EmbeddedMonitorService VERSION 1.0.0 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Include directories
include_directories(${CMAKE_SOURCE_DIR}/include)

# Define the main executable target
add_executable(monitor_service src/main.cpp)

# =============================================================================
# Static Linking Configuration
# Uses target_link_options() as per project conventions (NOT CMAKE_CXX_FLAGS)
# =============================================================================

if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    # Full static linking for embedded portability
    # Only apply when cross-compiling for Linux targets
    if(DEFINED CMAKE_SYSTEM_NAME AND CMAKE_SYSTEM_NAME STREQUAL "Linux")
        target_link_options(monitor_service PRIVATE 
            -static
            -Wl,--as-needed
        )
    endif()
    
    # Warning and optimization flags (not architecture-specific)
    target_compile_options(monitor_service PRIVATE
        -Wall
        -Wextra
        -Wpedantic
        -O2
        -fno-asynchronous-unwind-tables
    )
    
    # =============================================================================
    # Architecture-specific flags - ONLY when CMAKE_SYSTEM_PROCESSOR == aarch64
    # These should primarily be in CMakeToolchain.cmake, but we add conditional
    # flags here for completeness when the toolchain sets the processor
    # =============================================================================
    if(DEFINED CMAKE_SYSTEM_PROCESSOR AND CMAKE_SYSTEM_PROCESSOR STREQUAL "aarch64")
        target_compile_options(monitor_service PRIVATE -march=armv8-a)
    endif()
endif()

# =============================================================================
# Optional: Host-based unit test target
# Compiles and links against host compiler for testing parse functions
# =============================================================================

option(BUILD_TESTS "Build unit tests for host execution" OFF)

if(BUILD_TESTS)
    # Test executable uses the same source but compiled for host
    add_executable(test_runner 
        tests/test.cpp
        src/main.cpp
    )
    
    target_compile_definitions(test_runner PRIVATE UNIT_TEST_MODE)
    
    # Tests use host compiler, no static linking needed
    target_compile_options(test_runner PRIVATE
        -Wall
        -Wextra
        -Wpedantic
    )
    
    target_include_directories(test_runner PRIVATE ${CMAKE_SOURCE_DIR}/include)
endif()

# =============================================================================
# Build Information Output
# =============================================================================

message(STATUS "========================================")
message(STATUS "Build Configuration:")
message(STATUS "  Compiler: ${CMAKE_CXX_COMPILER}")
message(STATUS "  Compiler ID: ${CMAKE_CXX_COMPILER_ID}")
message(STATUS "  C++ Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "  System Name: ${CMAKE_SYSTEM_NAME}")
message(STATUS "  System Processor: ${CMAKE_SYSTEM_PROCESSOR}")
message(STATUS "  Cross-Compiling: ${CMAKE_CROSSCOMPILING}")
message(STATUS "========================================")
