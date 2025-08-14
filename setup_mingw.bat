@echo off
REM Dedicated script to setup MinGW-w64 for ctypesgen

echo Setting up MinGW-w64 for ctypesgen demo...

REM Check if CMake is available
cmake --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: CMake not found. Please install CMake first.
    exit /b 1
)

REM Create build directory for MinGW setup
if not exist build mkdir build
cd build

REM Configure CMake with MinGW setup only
echo Configuring MinGW auto-setup...
cmake -DAUTO_SETUP_MINGW=ON -DBUILD_SHARED_LIBS=OFF ..
if errorlevel 1 (
    echo ERROR: CMake configuration failed.
    exit /b 1
)

REM Run MinGW setup target
echo Running MinGW setup...
cmake --build . --target setup_mingw_env
if errorlevel 1 (
    echo WARNING: MinGW setup target failed, but MinGW might still be available
)

REM Test if MinGW is working
if exist setup_mingw_env.bat (
    echo Testing MinGW installation...
    call setup_mingw_env.bat
    echo.
    echo MinGW environment setup completed!
    echo You can now use GCC for ctypesgen preprocessing.
    echo.
    echo To use MinGW in this session, run: setup_mingw_env.bat
    echo To use MinGW in PowerShell, run: .\setup_mingw_env.ps1
) else (
    echo ERROR: MinGW setup scripts not found.
    echo Please check the CMake configuration output above for errors.
    exit /b 1
)

cd ..
echo.
echo MinGW-w64 setup completed successfully!
echo Run 'build.bat' to build the full project with MinGW support.
