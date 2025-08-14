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

REM Check if Git is available (needed for MinGW cloning)
git --version >nul 2>&1
if errorlevel 1 (
    echo WARNING: Git not found. 
    echo If MinGW download is needed, please install Git first.
    echo Download from: https://git-scm.com/download/win
    echo Continuing anyway...
)

REM Create build directory
if not exist build mkdir build
cd build

REM Configure with MinGW and ctypesgen auto-setup enabled
echo Configuring project with MinGW and ctypesgen auto-setup...
cmake -G "Visual Studio 17 2022" -A x64 -DAUTO_SETUP_MINGW=ON -DAUTO_SETUP_CTYPESGEN=ON .. || cmake -DAUTO_SETUP_MINGW=ON -DAUTO_SETUP_CTYPESGEN=ON ..
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

REM Test ctypesgen setup if available
if exist setup_ctypesgen_env.bat (
    echo Testing ctypesgen setup...
    cmake --build . --target test_ctypesgen --config Release
    if errorlevel 1 (
        echo WARNING: ctypesgen test failed, but continuing...
    )
)

REM Run C test
echo Running C test...
ctest -C Release -V
if errorlevel 1 (
    echo Warning: Some tests failed, but build completed.
)

REM Test ctypesgen with MinGW if both are available
echo Testing source-built development environment...
cmake --build . --target test_dev_env --config Release 2>nul
if errorlevel 1 (
    echo Note: Development environment test not available or failed
)

echo Build completed successfully!
echo.
echo Available targets:
echo   setup_mingw_env     - Set up MinGW environment
echo   setup_ctypesgen_env - Set up ctypesgen environment  
echo   setup_dev_env       - Set up complete development environment
echo   test_mingw          - Test MinGW installation
echo   test_ctypesgen      - Test ctypesgen installation
echo   test_dev_env        - Test complete development environment
echo   python_bindings     - Generate Python bindings with source-built tools
echo   run_python_demo     - Run Python demo
echo   demo_from_source    - Complete demo with source-built tools
echo.
echo To generate Python bindings: cmake --build . --target python_bindings --config Release
echo To run Python demo: cmake --build . --target run_python_demo --config Release

cd ..
