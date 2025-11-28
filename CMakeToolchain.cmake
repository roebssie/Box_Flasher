# CMake Toolchain File for Cross-Compilation to aarch64-linux-gnu
# Target: Amlogic S905W (aarch64 ARMv8) with Embedded Linux
# Build Host: Apple Silicon (M-series) macOS
#
# Usage: cmake -DCMAKE_TOOLCHAIN_FILE=CMakeToolchain.cmake -B build-aarch64 .

# Set this to the path where the aarch64-linux-gnu toolchain is installed
# On macOS with Homebrew, this is typically installed in /opt/homebrew or /usr/local
# This may need to be adjusted based on your specific installation

# Detect the toolchain path
# Supports both naming conventions:
# - aarch64-linux-gnu (traditional GNU)
# - aarch64-unknown-linux-gnu (Homebrew messense tap)

if(DEFINED TOOLCHAIN_PATH)
    set(TOOLCHAIN_PREFIX ${TOOLCHAIN_PATH})
else()
    # Try common macOS Homebrew paths for aarch64 Linux cross-compiler tools
    if(EXISTS "/opt/homebrew/bin/aarch64-unknown-linux-gnu-gcc")
        set(TOOLCHAIN_PREFIX "/opt/homebrew")
        set(TOOLCHAIN_TRIPLE "aarch64-unknown-linux-gnu")
    elseif(EXISTS "/opt/homebrew/bin/aarch64-linux-gnu-gcc")
        set(TOOLCHAIN_PREFIX "/opt/homebrew")
        set(TOOLCHAIN_TRIPLE "aarch64-linux-gnu")
    elseif(EXISTS "/usr/local/bin/aarch64-unknown-linux-gnu-gcc")
        set(TOOLCHAIN_PREFIX "/usr/local")
        set(TOOLCHAIN_TRIPLE "aarch64-unknown-linux-gnu")
    elseif(EXISTS "/usr/local/bin/aarch64-linux-gnu-gcc")
        set(TOOLCHAIN_PREFIX "/usr/local")
        set(TOOLCHAIN_TRIPLE "aarch64-linux-gnu")
    else()
        message(FATAL_ERROR 
            "aarch64 Linux toolchain not found in standard locations!\n"
            "Please install one of these:\n"
            "  Option A (Recommended): brew install messense/macos-cross-toolchains/aarch64-unknown-linux-gnu\n"
            "  Option B (Alternative): brew tap SergioBenitez/osxcross && brew install aarch64-linux-gnu"
        )
    endif()
endif()

# Set default triple if not already set
if(NOT DEFINED TOOLCHAIN_TRIPLE)
    set(TOOLCHAIN_TRIPLE "aarch64-unknown-linux-gnu")
endif()

message(STATUS "Using toolchain prefix: ${TOOLCHAIN_PREFIX}")
message(STATUS "Using toolchain triple: ${TOOLCHAIN_TRIPLE}")

# Specify the cross compiler
set(CMAKE_C_COMPILER "${TOOLCHAIN_PREFIX}/bin/${TOOLCHAIN_TRIPLE}-gcc" CACHE PATH "C Compiler")
set(CMAKE_CXX_COMPILER "${TOOLCHAIN_PREFIX}/bin/${TOOLCHAIN_TRIPLE}-g++" CACHE PATH "CXX Compiler")
set(CMAKE_AR "${TOOLCHAIN_PREFIX}/bin/${TOOLCHAIN_TRIPLE}-ar" CACHE PATH "AR Tool")
set(CMAKE_RANLIB "${TOOLCHAIN_PREFIX}/bin/${TOOLCHAIN_TRIPLE}-ranlib" CACHE PATH "RANLIB Tool")
set(CMAKE_STRIP "${TOOLCHAIN_PREFIX}/bin/${TOOLCHAIN_TRIPLE}-strip" CACHE PATH "STRIP Tool")

# Operating system settings
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)
set(CMAKE_SYSTEM_VERSION 1)

# Define sysroot path (optional, useful if you have a custom sysroot)
# For embedded Linux without a formal sysroot, this may not be needed
# set(CMAKE_SYSROOT "/path/to/sysroot")

# Compilation flags for aarch64-linux-gnu
set(CMAKE_C_FLAGS_INIT "-march=armv8-a -mtune=cortex-a53" CACHE STRING "C Flags")
set(CMAKE_CXX_FLAGS_INIT "-march=armv8-a -mtune=cortex-a53" CACHE STRING "CXX Flags")

# Linker flags for static linking to minimize runtime dependencies
set(CMAKE_EXE_LINKER_FLAGS_INIT "-static-libgcc -static-libstdc++ -Wl,--as-needed" CACHE STRING "Linker Flags")

# Important: Indicate that this is a cross-compilation environment
set(CMAKE_CROSSCOMPILING TRUE)

# Try to compile and link a simple test to verify the toolchain
set(CMAKE_TRY_COMPILE_TARGET_TYPE EXECUTABLE)

# Additional settings to skip unnecessary checks
set(CMAKE_C_ABI_COMPILED TRUE)
set(CMAKE_CXX_ABI_COMPILED TRUE)

# Compiler checks
message(STATUS "C Compiler: ${CMAKE_C_COMPILER}")
message(STATUS "C++ Compiler: ${CMAKE_CXX_COMPILER}")
message(STATUS "System: ${CMAKE_SYSTEM_NAME} ${CMAKE_SYSTEM_PROCESSOR}")
