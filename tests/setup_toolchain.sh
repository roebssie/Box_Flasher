#!/bin/bash

###########################################
# Setup Script for Cross-Compilation Toolchain
# Target: aarch64-linux-gnu (Amlogic S905W)
# Host: Apple Silicon macOS
###########################################

set -e

echo "========================================="
echo "Setting up aarch64-linux-gnu Toolchain"
echo "for Apple Silicon macOS"
echo "========================================="
echo ""

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

if command -v aarch64-linux-gnu-gcc &> /dev/null; then
    echo "✓ aarch64-linux-gnu-gcc found!"
    aarch64-linux-gnu-gcc --version | head -1
else
    echo "⚠ aarch64-linux-gnu toolchain not found in PATH"
    echo ""
    echo "To install the aarch64-linux-gnu toolchain on macOS, you have several options:"
    echo ""
    echo "Option 1: Using Homebrew with a tap (recommended):"
    echo "  brew tap SergioBenitez/osxcross"
    echo "  brew install aarch64-linux-gnu"
    echo ""
    echo "Option 2: Manual installation using osxcross:"
    echo "  git clone https://github.com/tpoechtrager/osxcross.git"
    echo "  cd osxcross"
    echo "  UNATTENDED=1 ./build_gcc.sh arm64e linux"
    echo ""
    echo "Option 3: Using crosstool-NG:"
    echo "  brew install crosstool-ng"
    echo "  # Then configure and build the aarch64-linux-gnu toolchain"
    echo ""
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

if aarch64-linux-gnu-g++ "$TEST_DIR/test.cpp" -o "$TEST_DIR/test" -static-libgcc -static-libstdc++ 2>/dev/null; then
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
