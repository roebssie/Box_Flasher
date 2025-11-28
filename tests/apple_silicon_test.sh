#!/bin/bash

#############################################################
# Apple Silicon Architecture Compatibility Test Suite
# Cross-Compilation Project: Embedded System Monitoring
# Target: aarch64 (ARM64) Embedded Linux
#############################################################

set -e

# Load centralized configuration if available
if [ -f ./scripts/load_config.sh ]; then
    # shellcheck disable=SC1090
    source ./scripts/load_config.sh
fi

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Logging functions
print_header() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} $1"
    echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}\n"
}

print_test() {
    echo -e "${CYAN}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}✓ PASS${NC}   $1"
    ((TESTS_PASSED++))
}

print_fail() {
    echo -e "${RED}✗ FAIL${NC}   $1"
    ((TESTS_FAILED++))
}

print_skip() {
    echo -e "${YELLOW}⊘ SKIP${NC}   $1"
    ((TESTS_SKIPPED++))
}

print_info() {
    echo -e "${YELLOW}ℹ INFO${NC}   $1"
}

# ==============================================================================
# TEST 1: Host System Verification
# ==============================================================================
print_header "TEST 1: Host System Verification"

print_test "Host architecture is Apple Silicon"
HOST_ARCH=$(uname -m)
if [ "$HOST_ARCH" = "arm64" ]; then
    print_pass "Host is Apple Silicon (arm64): $HOST_ARCH"
else
    print_fail "Host architecture mismatch: $HOST_ARCH (expected arm64)"
fi

print_test "macOS version compatibility"
MACOS_VERSION=$(sw_vers -productVersion)
MACOS_MAJOR=$(echo $MACOS_VERSION | cut -d. -f1)
if [ "$MACOS_MAJOR" -ge 11 ]; then
    print_pass "macOS version compatible: $MACOS_VERSION"
else
    print_fail "macOS version too old: $MACOS_VERSION (require 11.0+)"
fi

print_test "Homebrew is installed"
if command -v brew &> /dev/null; then
    BREW_VERSION=$(brew --version | head -1)
    print_pass "Homebrew available: $BREW_VERSION"
else
    print_fail "Homebrew not installed"
fi

# ==============================================================================
# TEST 2: Build Tools Verification
# ==============================================================================
print_header "TEST 2: Build Tools Verification"

print_test "CMake installation and version"
if command -v cmake &> /dev/null; then
    CMAKE_VERSION=$(cmake --version | head -1)
    print_pass "CMake available: $CMAKE_VERSION"
else
    print_fail "CMake not found"
fi

print_test "aarch64 cross-compiler availability"
if command -v aarch64-unknown-linux-gnu-g++ &> /dev/null; then
    COMPILER_PATH=$(which aarch64-unknown-linux-gnu-g++)
    COMPILER_VERSION=$(aarch64-unknown-linux-gnu-g++ --version | head -1)
    print_pass "Cross-compiler found: $COMPILER_PATH"
    print_info "Version: $COMPILER_VERSION"
elif command -v aarch64-linux-gnu-g++ &> /dev/null; then
    COMPILER_PATH=$(which aarch64-linux-gnu-g++)
    COMPILER_VERSION=$(aarch64-linux-gnu-g++ --version | head -1)
    print_pass "Cross-compiler found: $COMPILER_PATH"
    print_info "Version: $COMPILER_VERSION"
else
    print_fail "aarch64 cross-compiler not found"
fi

print_test "aarch64 binutils availability"
if command -v aarch64-unknown-linux-gnu-ar &> /dev/null || command -v aarch64-linux-gnu-ar &> /dev/null; then
    print_pass "aarch64 binutils available"
else
    print_skip "aarch64 binutils not found (optional)"
fi

# ==============================================================================
# TEST 3: Project Files Verification
# ==============================================================================
print_header "TEST 3: Project Files Verification"

PROJECT_ROOT=$(pwd)
REQUIRED_FILES=(
    "src/main.cpp"
    "CMakeLists.txt"
    "CMakeToolchain.cmake"
    "README.md"
    "REPORT.md"
)

for file in "${REQUIRED_FILES[@]}"; do
    print_test "Project file: $file"
    if [ -f "$file" ]; then
        SIZE=$(wc -l < "$file" 2>/dev/null || echo "unknown")
        print_pass "Found: $file ($SIZE lines)"
    else
        print_fail "Missing: $file"
    fi
done

# ==============================================================================
# TEST 4: Source Code Quality
# ==============================================================================
print_header "TEST 4: Source Code Quality"

print_test "C++ standard compliance (C++17)"
if grep -q "CXX_STANDARD 17" CMakeLists.txt; then
    print_pass "C++17 standard configured"
else
    print_fail "C++17 not found in CMakeLists.txt"
fi

print_test "No external library dependencies in main.cpp"
EXTERNAL_LIBS=$(grep -c "#include <" src/main.cpp || true)
print_info "Standard library includes: $EXTERNAL_LIBS"
if ! grep -q "Boost\|Qt\|GLib" src/main.cpp; then
    print_pass "No heavy external dependencies detected"
else
    print_fail "Found heavy dependencies"
fi

print_test "Error handling in monitoring functions"
if grep -q "try\|catch" src/main.cpp; then
    print_pass "Error handling present"
else
    print_warn "Consider adding explicit error handling"
fi

# ==============================================================================
# TEST 5: CMake Toolchain Configuration
# ==============================================================================
print_header "TEST 5: CMake Toolchain Configuration"

print_test "Toolchain file exists and is readable"
if [ -r "CMakeToolchain.cmake" ]; then
    print_pass "CMakeToolchain.cmake is readable"
else
    print_fail "CMakeToolchain.cmake not readable"
fi

print_test "Toolchain specifies aarch64 target"
if grep -q "aarch64\|ARM" CMakeToolchain.cmake; then
    print_pass "aarch64 target configured in toolchain"
else
    print_fail "aarch64 target not found in toolchain"
fi

print_test "Linux target system specified"
if grep -q "CMAKE_SYSTEM_NAME Linux" CMakeToolchain.cmake; then
    print_pass "Linux target system configured"
else
    print_fail "Linux target not specified"
fi

print_test "Static linking configured"
if grep -q "static-libgcc\|static-libstdc++" CMakeToolchain.cmake CMakeLists.txt; then
    print_pass "Static linking flags configured"
else
    print_fail "Static linking not configured"
fi

# ==============================================================================
# TEST 6: Cross-Compilation Test
# ==============================================================================
print_header "TEST 6: Cross-Compilation Test"

TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

print_test "Simple C++ cross-compilation"
cat > "$TEST_DIR/hello.cpp" << 'EOF'
#include <iostream>
int main() {
    std::cout << "Hello from aarch64!" << std::endl;
    return 0;
}
EOF

if command -v aarch64-unknown-linux-gnu-g++ &> /dev/null; then
    COMPILER="aarch64-unknown-linux-gnu-g++"
elif command -v aarch64-linux-gnu-g++ &> /dev/null; then
    COMPILER="aarch64-linux-gnu-g++"
else
    print_fail "No cross-compiler found"
    COMPILER=""
fi

if [ -n "$COMPILER" ]; then
    if $COMPILER "$TEST_DIR/hello.cpp" -o "$TEST_DIR/hello" -static-libgcc -static-libstdc++ 2>/dev/null; then
        print_pass "Cross-compilation successful"
        
        # Verify architecture
        if file "$TEST_DIR/hello" | grep -q "aarch64\|ARM aarch64"; then
            print_pass "Output is aarch64 architecture"
            FILE_INFO=$(file "$TEST_DIR/hello")
            print_info "File type: $FILE_INFO"
        else
            print_fail "Output is not aarch64"
        fi
        
        # Check size
        TEST_SIZE=$(du -h "$TEST_DIR/hello" | cut -f1)
        print_info "Test binary size: $TEST_SIZE"
    else
        print_fail "Cross-compilation failed"
    fi
fi

# ==============================================================================
# TEST 7: Build System Configuration
# ==============================================================================
print_header "TEST 7: Build System Configuration"

print_test "CMake configuration"
if [ ! -d "${BUILD_DIR:-build-aarch64}" ]; then
    if cmake -DCMAKE_TOOLCHAIN_FILE=CMakeToolchain.cmake -B "${BUILD_DIR:-build-aarch64}" . > /tmp/cmake_config.log 2>&1; then
        print_pass "CMake configuration successful"
    else
        print_fail "CMake configuration failed"
        print_info "See /tmp/cmake_config.log for details"
    fi
else
    print_skip "Build directory already exists (using existing)"
fi

print_test "Build directory structure"
if [ -f "${BUILD_DIR:-build-aarch64}/CMakeCache.txt" ]; then
    print_pass "CMake cache file created"
else
    print_fail "CMake cache file not found"
fi

# ==============================================================================
# TEST 8: Project Build
# ==============================================================================
print_header "TEST 8: Project Build"

print_test "Building monitor_service executable"
if cmake --build "${BUILD_DIR:-build-aarch64}" > /tmp/cmake_build.log 2>&1; then
    print_pass "Build completed successfully"
else
    print_fail "Build failed"
    print_info "See /tmp/cmake_build.log for details"
fi

# ==============================================================================
# TEST 9: Executable Verification
# ==============================================================================
print_header "TEST 9: Executable Verification"

EXECUTABLE="${BUILD_DIR:-build-aarch64}/monitor_service"

print_test "Executable exists"
if [ -f "$EXECUTABLE" ]; then
    print_pass "Executable found: $EXECUTABLE"
else
    print_fail "Executable not found"
fi

if [ -f "$EXECUTABLE" ]; then
    print_test "Executable is readable"
    if [ -r "$EXECUTABLE" ]; then
        print_pass "Executable is readable"
    else
        print_fail "Executable is not readable"
    fi

    print_test "Executable architecture is aarch64"
    FILE_OUTPUT=$(file "$EXECUTABLE")
    if echo "$FILE_OUTPUT" | grep -q "aarch64\|ARM aarch64"; then
        print_pass "Correct architecture: aarch64"
        print_info "File info: $(echo $FILE_OUTPUT | cut -d: -f2-)"
    else
        print_fail "Wrong architecture"
        print_info "File info: $FILE_OUTPUT"
    fi

    print_test "Executable binary size"
    SIZE=$(du -h "$EXECUTABLE" | cut -f1)
    STRIPPED_SIZE=$(du -h "$EXECUTABLE" | cut -f1)
    print_pass "Binary size: $SIZE"
    print_info "Note: Debug symbols included. Strip for production: aarch64-unknown-linux-gnu-strip"

    print_test "Executable dependencies"
    if command -v aarch64-unknown-linux-gnu-objdump &> /dev/null; then
        DEPS=$(aarch64-unknown-linux-gnu-objdump -p "$EXECUTABLE" 2>/dev/null | grep "NEEDED" | wc -l)
        print_info "Dynamic dependencies: $DEPS"
    elif command -v aarch64-linux-gnu-objdump &> /dev/null; then
        DEPS=$(aarch64-linux-gnu-objdump -p "$EXECUTABLE" 2>/dev/null | grep "NEEDED" | wc -l)
        print_info "Dynamic dependencies: $DEPS"
    else
        print_skip "objdump not available"
    fi

    print_test "Executable is ELF format"
    if file "$EXECUTABLE" | grep -q "ELF"; then
        print_pass "Valid ELF executable"
    else
        print_fail "Not a valid ELF file"
    fi
fi

# ==============================================================================
# TEST 10: Deployment Scripts
# ==============================================================================
print_header "TEST 10: Deployment Scripts"

SCRIPTS=(
    "setup_toolchain.sh"
    "deployment_test.sh"
    "test.sh"
)

for script in "${SCRIPTS[@]}"; do
    print_test "Script exists and is executable: $script"
    if [ -x "$script" ]; then
        print_pass "Found executable: $script"
    elif [ -f "$script" ]; then
        print_fail "Script exists but not executable: $script"
    else
        print_skip "Script not found: $script"
    fi
done

# ==============================================================================
# TEST 11: Documentation
# ==============================================================================
print_header "TEST 11: Documentation"

DOCS=(
    "README.md"
    "REPORT.md"
    "QUICKSTART.md"
    "PROJECT_STATUS.md"
)

for doc in "${DOCS[@]}"; do
    print_test "Documentation: $doc"
    if [ -f "$doc" ]; then
        LINES=$(wc -l < "$doc")
        print_pass "Found: $doc ($LINES lines)"
    else
        print_skip "Not found: $doc"
    fi
done

# ==============================================================================
# TEST 12: Integration Check
# ==============================================================================
print_header "TEST 12: Integration Check"

print_test "All build artifacts in place"
ARTIFACTS=(
    "src/main.cpp"
    "CMakeLists.txt"
    "CMakeToolchain.cmake"
    "build-aarch64/monitor_service"
)

ARTIFACTS_FOUND=0
for artifact in "${ARTIFACTS[@]}"; do
    if [ -f "$artifact" ]; then
        ((ARTIFACTS_FOUND++))
    fi
done

if [ $ARTIFACTS_FOUND -eq ${#ARTIFACTS[@]} ]; then
    print_pass "All critical artifacts present ($ARTIFACTS_FOUND/${#ARTIFACTS[@]})"
else
    print_fail "Missing artifacts ($ARTIFACTS_FOUND/${#ARTIFACTS[@]})"
fi

# ==============================================================================
# Final Summary
# ==============================================================================
print_header "Test Summary"

TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))
echo -e "${GREEN}Passed:  $TESTS_PASSED${NC}"
echo -e "${RED}Failed:  $TESTS_FAILED${NC}"
echo -e "${YELLOW}Skipped: $TESTS_SKIPPED${NC}"
echo -e "Total:   $TOTAL_TESTS"

if [ $TESTS_FAILED -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ All critical tests passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Project is ready for deployment"
    echo "  2. Run: ./deployment_test.sh (to deploy to device)"
    echo "  3. Or: scp ${BUILD_DIR:-build-aarch64}/monitor_service root@<device>:/tmp/"
    exit 0
else
    echo ""
    echo -e "${RED}✗ Some tests failed. Please review above.${NC}"
    exit 1
fi
