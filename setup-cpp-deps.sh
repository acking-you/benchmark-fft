#!/bin/bash

# Script to setup vcpkg and install dependencies for C++ FFT implementation
# This script will check if vcpkg is already installed via VCPKG_ROOT environment variable

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if vcpkg is already installed
if [ -n "$VCPKG_ROOT" ] && [ -d "$VCPKG_ROOT" ]; then
    print_success "vcpkg is already installed at: $VCPKG_ROOT"
    VCPKG_EXECUTABLE="$VCPKG_ROOT/vcpkg"
    
    # Verify vcpkg executable exists
    if [ ! -f "$VCPKG_EXECUTABLE" ]; then
        print_error "vcpkg executable not found at $VCPKG_EXECUTABLE"
        exit 1
    fi
else
    print_info "VCPKG_ROOT environment variable not set or directory doesn't exist"
    print_info "Installing vcpkg locally..."
    
    # Create vcpkg directory in project root (use absolute path)
    PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
    VCPKG_DIR="$PROJECT_ROOT/vcpkg"
    
    # Check if vcpkg directory already exists
    if [ -d "$VCPKG_DIR" ]; then
        print_warning "vcpkg directory already exists at $VCPKG_DIR"
        print_info "Updating existing vcpkg installation..."
        cd "$VCPKG_DIR"
        git pull
        cd "$PROJECT_ROOT"
    else
        print_info "Cloning vcpkg repository..."
        git clone https://github.com/Microsoft/vcpkg.git "$VCPKG_DIR"
    fi
    
    # Bootstrap vcpkg
    print_info "Bootstrapping vcpkg..."
    cd "$VCPKG_DIR"
    
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        # Windows
        ./bootstrap-vcpkg.bat
        VCPKG_EXECUTABLE="./vcpkg.exe"
    else
        # Linux/Mac
        ./bootstrap-vcpkg.sh
        VCPKG_EXECUTABLE="./vcpkg"
    fi
    
    cd "$PROJECT_ROOT"
    
    # Set VCPKG_ROOT for this session (absolute path)
    export VCPKG_ROOT="$VCPKG_DIR"
    print_success "vcpkg installed successfully at $VCPKG_DIR"
    
    # Set environment variable for current session and future sessions
    print_info "Setting VCPKG_ROOT environment variable..."
    export VCPKG_ROOT="$VCPKG_DIR"
    
    # Add to shell configuration files
    SHELL_CONFIG=""
    if [ -f "$HOME/.bashrc" ]; then
        SHELL_CONFIG="$HOME/.bashrc"
    elif [ -f "$HOME/.zshrc" ]; then
        SHELL_CONFIG="$HOME/.zshrc"
    elif [ -f "$HOME/.profile" ]; then
        SHELL_CONFIG="$HOME/.profile"
    fi
    
    if [ -n "$SHELL_CONFIG" ]; then
        # Check if VCPKG_ROOT is already in the config file
        if ! grep -q "export VCPKG_ROOT=" "$SHELL_CONFIG"; then
            print_info "Adding VCPKG_ROOT to $SHELL_CONFIG"
            echo "" >> "$SHELL_CONFIG"
            echo "# Added by setup-cpp-deps.sh" >> "$SHELL_CONFIG"
            echo "export VCPKG_ROOT=\"$VCPKG_DIR\"" >> "$SHELL_CONFIG"
            print_success "VCPKG_ROOT added to $SHELL_CONFIG"
        else
            print_info "VCPKG_ROOT already exists in $SHELL_CONFIG"
        fi
    fi
fi

# Check for required dependencies (currently none for our FFT implementation)
print_info "Checking C++ FFT implementation dependencies..."

# Our current implementation only uses standard library features
# No additional vcpkg packages are needed for:
# - std::complex
# - std::ranges
# - std::numbers
# - std::chrono
print_success "No additional vcpkg packages required for C++23 FFT implementation"

# Verify C++23 compiler support
print_info "Verifying C++23 compiler support..."

# Check for GCC version
if command -v g++ &> /dev/null; then
    GCC_VERSION=$(g++ --version | head -n1 | grep -oP '\d+\.\d+' | head -1)
    print_info "Found GCC version: $GCC_VERSION"
    
    # GCC 11+ has partial C++23 support, GCC 13+ has better support
    if [[ $(echo "$GCC_VERSION >= 11.0" | bc -l 2>/dev/null || echo "0") == "1" ]]; then
        print_success "GCC version supports C++23 features"
    else
        print_warning "GCC version may not fully support C++23 features (requires GCC 11+)"
    fi
fi

# Check for Clang version
if command -v clang++ &> /dev/null; then
    CLANG_VERSION=$(clang++ --version | head -n1 | grep -oP '\d+\.\d+' | head -1)
    print_info "Found Clang version: $CLANG_VERSION"
    
    # Clang 15+ has good C++23 support
    if [[ $(echo "$CLANG_VERSION >= 15.0" | bc -l 2>/dev/null || echo "0") == "1" ]]; then
        print_success "Clang version supports C++23 features"
    else
        print_warning "Clang version may not fully support C++23 features (requires Clang 15+)"
    fi
fi

# Check CMake version
if command -v cmake &> /dev/null; then
    CMAKE_VERSION=$(cmake --version | head -n1 | grep -oP '\d+\.\d+')
    print_info "Found CMake version: $CMAKE_VERSION"
    
    if [[ $(echo "$CMAKE_VERSION >= 3.20" | bc -l 2>/dev/null || echo "0") == "1" ]]; then
        print_success "CMake version is sufficient (requires 3.20+)"
    else
        print_error "CMake version is too old (requires 3.20+, found $CMAKE_VERSION)"
        exit 1
    fi
else
    print_error "CMake not found. Please install CMake 3.20 or later"
    exit 1
fi

print_success "Setup completed successfully!"
print_info "VCPKG_ROOT environment variable has been set to: $VCPKG_ROOT"
print_info ""
print_info "To make the environment variable available in your current shell, run:"
print_info "  source ~/.zshrc"
print_info "  # or source ~/.bashrc if using bash"
print_info ""
print_info "You can now build the C++ FFT implementation using:"
print_info "  cd fft/cpp"
print_info "  cmake --preset=vcpkg"
print_info "  cmake --build --preset=vcpkg"