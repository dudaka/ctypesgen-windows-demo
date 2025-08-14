@echo off
REM Simple build script for Windows using CMake

echo Building ctypesgen demo with CMake...

REM Check if CMake is available
cmake --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: CMake not found. Please install CMake first.
    echo Download from: https://cmake.org/download/
    exit /b 1
)

REM Create build directory
if not exist build mkdir build
cd build

REM Configure
echo Configuring project...
cmake -G "Visual Studio 17 2022" -A x64 .. || cmake ..
if errorlevel 1 (
    echo ERROR: CMake configuration failed.
    exit /b 1
)

REM Build
echo Building project...
cmake --build . --config Release
if errorlevel 1 (
    echo ERROR: Build failed.
    exit /b 1
)

REM Run test
echo Running test...
ctest -C Release -V
if errorlevel 1 (
    echo Warning: Some tests failed, but build completed.
)

echo Build completed successfully!
echo.
echo To generate Python bindings: cmake --build . --target python_bindings --config Release
echo To run Python demo: cmake --build . --target run_python_demo --config Release

cd ..
