#!/bin/bash

###########################################
# Setup Script for Cross-Compilation Toolchain
# Target: aarch64-linux-gnu (Amlogic S905W)
# Host: macOS (Apple Silicon), Linux, or Windows (MinGW/Git Bash)
###########################################

set -e

echo "========================================="
echo "Setting up aarch64-linux-gnu Toolchain"
echo "========================================="
echo ""

# Detect OS
OS_TYPE="$(uname -s)"
echo "Detected OS: $OS_TYPE"

if [[ "$OS_TYPE" == "Darwin" ]]; then
    # macOS Setup
    echo "Running macOS setup..."
    
    # Step 1: Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        echo "Error: Homebrew is not installed!"
        echo "Please install Homebrew from https://brew.sh"
        exit 1
    fi

    echo "[1/5] Checking Homebrew..."
    brew --version
    echo ""

    # Step 2: Install required build tools
    echo "[2/5] Installing/verifying build tools..."
    brew install cmake gcc wget 2>&1 | tail -5 || true
    echo ""

    # Step 3: Download and compile aarch64-linux-gnu toolchain if needed
    echo "[3/5] Checking for aarch64-linux-gnu toolchain..."

    if command -v aarch64-linux-gnu-gcc &> /dev/null || command -v aarch64-unknown-linux-gnu-gcc &> /dev/null; then
        echo "✓ aarch64-linux-gnu-gcc found!"
    else
        echo "⚠ aarch64-linux-gnu toolchain not found in PATH"
        echo "Installing via Homebrew..."
        brew tap messense/macos-cross-toolchains
        brew install messense/macos-cross-toolchains/aarch64-unknown-linux-gnu
    fi

elif [[ "$OS_TYPE" == "Linux" ]]; then
    # Linux/WSL Setup
    echo "Running Linux/WSL setup..."
    
    # Check for apt-get (Debian/Ubuntu)
    if command -v apt-get &> /dev/null; then
        echo "[1/5] Updating package lists..."
        sudo apt-get update
        
        echo "[2/5] Installing build tools..."
        sudo apt-get install -y cmake build-essential wget
        
        echo "[3/5] Installing cross-compiler..."
        sudo apt-get install -y g++-aarch64-linux-gnu
    else
        echo "⚠ Unsupported Linux distribution (apt-get not found)."
        echo "Please manually install: cmake, build-essential, g++-aarch64-linux-gnu"
        exit 1
    fi

elif [[ "$OS_TYPE" == MINGW* ]] || [[ "$OS_TYPE" == MSYS* ]] || [[ "$OS_TYPE" == CYGWIN* ]]; then
    # Windows Setup (MinGW/Git Bash)
    echo "Running Windows (MinGW/Git Bash) setup..."
    
    # Check for cmake
    if ! command -v cmake &> /dev/null; then
        echo "⚠ CMake not found in PATH."
        
        if command -v winget &> /dev/null; then
            echo "Attempting to install CMake via winget..."
            if winget install -e --id Kitware.CMake; then
                echo "✓ CMake installed successfully."
                echo "Please restart your terminal to refresh PATH."
                exit 0
            else
                echo "✗ Failed to install CMake via winget."
            fi
        else
            echo "winget not found."
        fi
        
        echo "Please install CMake manually:"
        echo "  1. Download: https://cmake.org/download/"
        echo "  2. Install and select 'Add CMake to the system PATH'"
        exit 1
    fi

    # Check for compiler
    # Windows users often use the official Arm toolchain which uses 'aarch64-none-linux-gnu-' prefix
    if command -v aarch64-linux-gnu-g++ &> /dev/null; then
        echo "✓ aarch64-linux-gnu-g++ found!"
    elif command -v aarch64-none-linux-gnu-g++ &> /dev/null; then
        echo "✓ aarch64-none-linux-gnu-g++ found!"
    else
        echo "⚠ aarch64-linux-gnu toolchain not found in PATH"
        echo "Please install the Arm GNU Toolchain for Windows:"
        echo "  Recommended Version: 14.3.Rel1"
        echo "  File: arm-gnu-toolchain-14.3.rel1-mingw-w64-x86_64-aarch64-none-linux-gnu.exe"
        echo "  Download: https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads"
        echo ""
        echo "  Installation Steps:"
        echo "  1. Download the installer above."
        echo "  2. Run the installer."
        echo "  3. CRITICAL: Check the box 'Add path to environment variable' during installation."
        echo "  4. Restart your terminal (Git Bash) after installation."
        exit 1
    fi

else
    echo "⚠ Unsupported Operating System: $OS_TYPE"
    echo "This script supports macOS, Linux, and Windows (MinGW/Git Bash)."
    exit 1
fi

echo ""
echo "[4/5] Verifying CMake..."
cmake --version | head -1
echo ""

# Step 4: Create a simple test
echo "[5/5] Verifying cross-compiler with a test compilation..."

TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

cat > "$TEST_DIR/test.cpp" << 'EOF'
#include <iostream>
int main() {
    std::cout << "Hello from aarch64!" << std::endl;
    return 0;
}
EOF

# Try common names
COMPILER="aarch64-linux-gnu-g++"
if ! command -v $COMPILER &> /dev/null; then
    COMPILER="aarch64-unknown-linux-gnu-g++"
fi
if ! command -v $COMPILER &> /dev/null; then
    COMPILER="aarch64-none-linux-gnu-g++"
fi

if $COMPILER "$TEST_DIR/test.cpp" -o "$TEST_DIR/test" -static-libgcc -static-libstdc++ 2>/dev/null; then
    echo "✓ Cross-compilation test successful!"
    file "$TEST_DIR/test"
else
    echo "⚠ Cross-compilation test failed."
    echo "  Please verify the toolchain installation."
    exit 1
fi

echo ""
echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "You can now build the project with:"
echo "  cmake -DCMAKE_TOOLCHAIN_FILE=CMakeToolchain.cmake -B build-aarch64 ."
echo "  cmake --build build-aarch64"
echo ""
