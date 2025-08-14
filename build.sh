#!/bin/bash
# Simple build script for Linux/macOS using CMake

echo "Building ctypesgen demo with CMake..."

# Check if CMake is available
if ! command -v cmake &> /dev/null; then
    echo "ERROR: CMake not found. Please install CMake first."
    exit 1
fi

# Create build directory
mkdir -p build
cd build

# Configure
echo "Configuring project..."
cmake ..
if [ $? -ne 0 ]; then
    echo "ERROR: CMake configuration failed."
    exit 1
fi

# Build
echo "Building project..."
cmake --build . --config Release
if [ $? -ne 0 ]; then
    echo "ERROR: Build failed."
    exit 1
fi

# Run test
echo "Running test..."
if command -v ctest &> /dev/null; then
    # For single-config generators, don't use -C flag
    if [ -f "CMakeCache.txt" ] && grep -q "CMAKE_CONFIGURATION_TYPES" CMakeCache.txt; then
        ctest -C Release -V
    else
        ctest -V
    fi
else
    echo "CTest not available, skipping tests"
fi

echo "Build completed successfully!"
echo ""
echo "To generate Python bindings: cmake --build . --target python_bindings --config Release"
echo "To run Python demo: cmake --build . --target run_python_demo --config Release"

cd ..
