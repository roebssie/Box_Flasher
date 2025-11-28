cmake_minimum_required(VERSION 3.10)

# Project name and version
project(EmbeddedMonitorService VERSION 1.0.0 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Define the executable target
add_executable(monitor_service src/main.cpp)

# Compiler flags for static linking to minimize dependencies
# These flags ensure the executable is self-contained for embedded Linux

# Static linking of standard libraries
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    # Full static linking for embedded portability
    # For cross-compilation on Linux, add static link flags
    if(DEFINED CMAKE_SYSTEM_NAME AND CMAKE_SYSTEM_NAME STREQUAL "Linux")
        target_link_options(monitor_service PRIVATE 
            -static
            -Wl,--as-needed
        )
    endif()
    
    # Additional hardening and optimization flags
    target_compile_options(monitor_service PRIVATE
        -Wall
        -Wextra
        -Wpedantic
        -O2
        -fno-asynchronous-unwind-tables
    )
    
    # For cross-compilation to aarch64-linux-gnu
    if(DEFINED CMAKE_SYSTEM_NAME AND CMAKE_SYSTEM_NAME STREQUAL "Linux")
        if(DEFINED CMAKE_SYSTEM_PROCESSOR AND CMAKE_SYSTEM_PROCESSOR STREQUAL "aarch64")
            # Additional flags specific to aarch64
            target_compile_options(monitor_service PRIVATE -march=armv8-a)
        endif()
    endif()
endif()

# Print build information
message(STATUS "Compiler: ${CMAKE_CXX_COMPILER}")
message(STATUS "Compiler ID: ${CMAKE_CXX_COMPILER_ID}")
message(STATUS "C++ Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "Target: ${CMAKE_SYSTEM_NAME} ${CMAKE_SYSTEM_PROCESSOR}")
