@echo off
REM Enhanced build script for Windows using CMake with MinGW auto-setup

echo Building ctypesgen demo with CMake and MinGW auto-setup...

REM Check if CMake is available
cmake --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: CMake not found. Please install CMake first.
    echo Download from: https://cmake.org/download/
    exit /b 1
)

REM Check if 7zip is available (needed for MinGW extraction)
7z.exe >nul 2>&1
if errorlevel 1 (
    echo WARNING: 7zip not found. 
    echo If MinGW download is needed, please install 7zip first.
    echo Download from: https://www.7-zip.org/
    echo Continuing anyway...
)

REM Create build directory
if not exist build mkdir build
cd build

REM Configure with MinGW auto-setup enabled
echo Configuring project with MinGW auto-setup...
cmake -G "Visual Studio 17 2022" -A x64 -DAUTO_SETUP_MINGW=ON .. || cmake -DAUTO_SETUP_MINGW=ON ..
if errorlevel 1 (
    echo ERROR: CMake configuration failed.
    exit /b 1
)

REM Build the library
echo Building project...
cmake --build . --config Release
if errorlevel 1 (
    echo ERROR: Build failed.
    exit /b 1
)

REM Test MinGW setup if available
if exist setup_mingw_env.bat (
    echo Testing MinGW setup...
    cmake --build . --target test_mingw --config Release
    if errorlevel 1 (
        echo WARNING: MinGW test failed, but continuing...
    )
)

REM Run C test
echo Running C test...
ctest -C Release -V
if errorlevel 1 (
    echo Warning: Some tests failed, but build completed.
)

REM Test ctypesgen with MinGW if available
echo Testing ctypesgen with MinGW...
cmake --build . --target test_ctypesgen_mingw --config Release 2>nul
if errorlevel 1 (
    echo Note: ctypesgen MinGW test not available or failed
)

echo Build completed successfully!
echo.
echo Available targets:
echo   setup_mingw_env     - Set up MinGW environment
echo   test_mingw          - Test MinGW installation  
echo   python_bindings     - Generate Python bindings with MinGW
echo   run_python_demo     - Run Python demo
echo   demo_with_mingw     - Complete demo with MinGW
echo.
echo To generate Python bindings: cmake --build . --target python_bindings --config Release
echo To run Python demo: cmake --build . --target run_python_demo --config Release

cd ..
