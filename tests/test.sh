#!/bin/bash

##############################################
# Complete Verification & Build Test Script
# Embedded System Monitoring Service
##############################################

set -e

COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${COLOR_BLUE}════════════════════════════════════════${NC}"
    echo -e "${COLOR_BLUE}$1${NC}"
    echo -e "${COLOR_BLUE}════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${COLOR_GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${COLOR_RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${COLOR_YELLOW}⚠ $1${NC}"
}

if [ -f ./scripts/load_config.sh ]; then
    # shellcheck disable=SC1090
    source ./scripts/load_config.sh
fi

print_header "Cross-Compilation Verification & Build Test"

# Test 1: CMake availability
echo "Test 1: Checking CMake..."
if command -v cmake &> /dev/null; then
    CMAKE_VERSION=$(cmake --version | head -1)
    print_success "CMake available: $CMAKE_VERSION"
else
    print_error "CMake not found!"
    exit 1
fi

# Test 2: aarch64 cross-compiler availability
echo -e "\nTest 2: Checking aarch64 cross-compiler..."
CROSS_COMPILER=""
if command -v aarch64-unknown-linux-gnu-g++ &> /dev/null; then
    CROSS_COMPILER="aarch64-unknown-linux-gnu-g++"
    print_success "Found: aarch64-unknown-linux-gnu-g++"
elif command -v aarch64-linux-gnu-g++ &> /dev/null; then
    CROSS_COMPILER="aarch64-linux-gnu-g++"
    print_success "Found: aarch64-linux-gnu-g++"
elif command -v aarch64-none-linux-gnu-g++ &> /dev/null; then
    CROSS_COMPILER="aarch64-none-linux-gnu-g++"
    print_success "Found: aarch64-none-linux-gnu-g++"
else
    print_error "aarch64 cross-compiler not found!"
    echo ""
    echo "Installation instructions:"
    echo "  macOS: brew install messense/macos-cross-toolchains/aarch64-unknown-linux-gnu"
    echo "  Linux: sudo apt-get install g++-aarch64-linux-gnu"
    echo "  Windows: Install Arm GNU Toolchain (aarch64-none-linux-gnu)"
    exit 1
fi

COMPILER_VERSION=$($CROSS_COMPILER --version | head -1)
echo "  Version: $COMPILER_VERSION"

# Test 3: Build system files
echo -e "\nTest 3: Verifying project files..."
REQUIRED_FILES=(
    "src/main.cpp"
    "CMakeLists.txt"
    "CMakeToolchain.cmake"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_success "Found: $file"
    else
        print_error "Missing: $file"
        exit 1
    fi
done

# Test 4: Simple compilation test
echo -e "\nTest 4: Testing cross-compilation..."
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

cat > "$TEST_DIR/test.cpp" << 'EOF'
#include <iostream>
#include <string>

int main() {
    std::string msg = "Hello from aarch64!";
    std::cout << msg << std::endl;
    return 0;
}
EOF

if $CROSS_COMPILER "$TEST_DIR/test.cpp" -o "$TEST_DIR/test" -static-libgcc -static-libstdc++ 2>/dev/null; then
    print_success "Cross-compilation successful"
    
    # Check architecture
    if file "$TEST_DIR/test" | grep -q "aarch64\|ARM aarch64"; then
        print_success "Output is aarch64 architecture"
    else
        print_warning "Could not verify aarch64 architecture"
        file "$TEST_DIR/test"
    fi
    
    # Check linking
    if file "$TEST_DIR/test" | grep -q "statically linked"; then
        print_success "Binary is statically linked"
    else
        print_warning "Binary may have dynamic dependencies"
    fi
else
    print_error "Cross-compilation failed"
    exit 1
fi

# Test 5: CMake configuration
echo -e "\nTest 5: Testing CMake configuration..."
rm -rf "${BUILD_DIR:-build-aarch64}" 2>/dev/null || true

if cmake -DCMAKE_TOOLCHAIN_FILE=CMakeToolchain.cmake -B "${BUILD_DIR:-build-aarch64}" . > /dev/null 2>&1; then
    print_success "CMake configuration successful"
else
    print_error "CMake configuration failed"
    cmake -DCMAKE_TOOLCHAIN_FILE=CMakeToolchain.cmake -B "${BUILD_DIR:-build-aarch64}" .
    exit 1
fi

# Test 6: Build project
echo -e "\nTest 6: Building monitor_service..."
if cmake --build "${BUILD_DIR:-build-aarch64}" > /dev/null 2>&1; then
    print_success "Build successful"
else
    print_error "Build failed"
    cmake --build "${BUILD_DIR:-build-aarch64}"
    exit 1
fi

# Test 7: Verify executable
echo -e "\nTest 7: Verifying built executable..."
if [ -f "${BUILD_DIR:-build-aarch64}/monitor_service" ]; then
    print_success "Executable exists: ${BUILD_DIR:-build-aarch64}/monitor_service"
    
    SIZE=$(du -h "${BUILD_DIR:-build-aarch64}/monitor_service" | cut -f1)
    echo "  Size: $SIZE"
    
    FILE_INFO=$(file "${BUILD_DIR:-build-aarch64}/monitor_service")
    echo "  Type: $FILE_INFO"
    
    if echo "$FILE_INFO" | grep -q "aarch64\|ARM aarch64"; then
        print_success "Correct architecture (aarch64)"
    else
        print_error "Wrong architecture!"
        exit 1
    fi
    
    if echo "$FILE_INFO" | grep -q "statically linked"; then
        print_success "Statically linked ✓"
    else
        print_warning "May have dynamic dependencies"
    fi
else
    print_error "Executable not found!"
    exit 1
fi

# Summary
print_header "All Verification Tests Passed!"

echo -e "${COLOR_GREEN}Project is ready for deployment!${NC}\n"
echo "Next steps:"
echo "  1. Transfer binary to target device:"
echo "     scp ${BUILD_DIR:-build-aarch64}/monitor_service root@<device-ip>:/tmp/"
echo ""
echo "  2. Execute on target device:"
echo "     ssh root@<device-ip> \"/tmp/monitor_service\""
echo ""
echo "  3. For persistent installation, see REPORT.md Deployment section"
echo ""
