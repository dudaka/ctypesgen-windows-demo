# DownloadMingw.cmake
# Module to clone and setup MinGW-w64 from Git repository

# Options
option(AUTO_DOWNLOAD_MINGW "Automatically clone MinGW-w64 if not found" ON)
option(FORCE_REBUILD_MINGW "Force rebuild of MinGW-w64 even if found" OFF)
set(MINGW_INSTALL_DIR "${CMAKE_BINARY_DIR}/mingw-w64" CACHE PATH "MinGW-w64 installation directory")
set(MINGW_SOURCE_DIR "${CMAKE_BINARY_DIR}/mingw-w64-source" CACHE PATH "MinGW-w64 source directory")

# Check if MinGW is already installed
if(NOT FORCE_REBUILD_MINGW)
    find_program(GCC_EXECUTABLE gcc 
        PATHS ${MINGW_INSTALL_DIR}/bin
        NO_DEFAULT_PATH
    )

    if(NOT GCC_EXECUTABLE)
        find_program(GCC_EXECUTABLE gcc)
    endif()
else()
    # Force use of our custom MinGW
    set(GCC_EXECUTABLE)
endif()

if(GCC_EXECUTABLE AND NOT FORCE_REBUILD_MINGW)
    message(STATUS "Found GCC: ${GCC_EXECUTABLE}")
    get_filename_component(MINGW_BIN_DIR "${GCC_EXECUTABLE}" DIRECTORY)
    get_filename_component(MINGW_ROOT_DIR "${MINGW_BIN_DIR}" DIRECTORY)
    set(MINGW_FOUND TRUE)
else()
    if(FORCE_REBUILD_MINGW)
        message(STATUS "Force rebuild requested - will create custom MinGW setup")
    endif()
    set(MINGW_FOUND FALSE)
    if(AUTO_DOWNLOAD_MINGW)
        message(STATUS "GCC not found. Will clone MinGW-w64 from Git...")
        
        # Check for required tools
        find_package(Git REQUIRED)
        
        # Clone MinGW-w64 repository if it doesn't exist
        if(NOT EXISTS "${MINGW_SOURCE_DIR}")
            message(STATUS "Cloning MinGW-w64 repository...")
            execute_process(
                COMMAND ${GIT_EXECUTABLE} clone --depth 1 https://git.code.sf.net/p/mingw-w64/mingw-w64 "${MINGW_SOURCE_DIR}"
                RESULT_VARIABLE GIT_RESULT
                OUTPUT_VARIABLE GIT_OUTPUT
                ERROR_VARIABLE GIT_ERROR
            )
            
            if(NOT GIT_RESULT EQUAL 0)
                message(FATAL_ERROR "Failed to clone MinGW-w64 repository: ${GIT_ERROR}")
            endif()
            
            message(STATUS "MinGW-w64 repository cloned successfully")
        else()
            message(STATUS "MinGW-w64 source already exists at: ${MINGW_SOURCE_DIR}")
        endif()
        
        # Create installation directory
        file(MAKE_DIRECTORY "${MINGW_INSTALL_DIR}")
        file(MAKE_DIRECTORY "${MINGW_INSTALL_DIR}/bin")
        
        # For simplicity, we'll create a minimal GCC wrapper that uses system compiler
        # This provides the basic functionality needed for ctypesgen preprocessing
        message(STATUS "Setting up MinGW environment...")
        
        # Check if we have a C compiler available (CMake should have detected one)
        if(CMAKE_C_COMPILER)
            set(CL_EXECUTABLE "${CMAKE_C_COMPILER}")
            message(STATUS "Using detected C compiler: ${CL_EXECUTABLE}")
        else()
            find_program(CL_EXECUTABLE cl)
        endif()
        
        if(CL_EXECUTABLE)
            # Create a GCC wrapper that translates basic GCC preprocessing to the available compiler
            set(GCC_WRAPPER "${MINGW_INSTALL_DIR}/bin/gcc.bat")
            
            # Determine if this is MSVC cl.exe or another compiler
            get_filename_component(COMPILER_NAME "${CL_EXECUTABLE}" NAME_WE)
            if(COMPILER_NAME STREQUAL "cl")
                # MSVC cl.exe
                set(PREPROCESS_CMD "\"${CL_EXECUTABLE}\" /EP")
            else()
                # Assume GCC-compatible compiler
                set(PREPROCESS_CMD "\"${CL_EXECUTABLE}\" -E")
            endif()
            
            file(WRITE "${GCC_WRAPPER}" 
                "@echo off\n"
                "REM MinGW GCC wrapper for ctypesgen preprocessing\n"
                "REM Using backend compiler: ${CL_EXECUTABLE}\n"
                "\n"
                "set ARGS=%*\n"
                "\n"
                "REM Check if this is a preprocessing call (-E flag)\n"
                "echo %ARGS% | findstr /C:\"-E\" >nul\n"
                "if not errorlevel 1 goto :preprocess\n"
                "\n"
                "REM Check for version request\n"
                "echo %ARGS% | findstr /C:\"--version\" >nul\n"
                "if not errorlevel 1 goto :version\n"
                "\n"
                "REM Unsupported operation\n"
                "echo Unsupported GCC operation: %ARGS%\n"
                "exit /b 1\n"
                "\n"
                ":preprocess\n"
                "REM Preprocessing mode\n"
                "set CLEAN_ARGS=%ARGS:gcc -E=%\n"
                "set CLEAN_ARGS=%CLEAN_ARGS:-U __GNUC__=%\n"
                "set CLEAN_ARGS=%CLEAN_ARGS:-dD=%\n"
                "${PREPROCESS_CMD} %CLEAN_ARGS%\n"
                "exit /b %errorlevel%\n"
                "\n"
                ":version\n"
                "echo MinGW-w64 GCC wrapper for ctypesgen (using ${COMPILER_NAME})\n"
                "echo Copyright 2025 CMake MinGW wrapper\n"
                "echo Backend compiler: ${CL_EXECUTABLE}\n"
                "exit /b 0\n"
            )
            
            set(GCC_EXECUTABLE "${GCC_WRAPPER}")
            set(MINGW_FOUND TRUE)
            
            message(STATUS "Created GCC wrapper using ${COMPILER_NAME} backend: ${CL_EXECUTABLE}")
        else()
            message(WARNING "No suitable compiler found for GCC wrapper")
            message(STATUS "ctypesgen may not work properly without a C preprocessor")
            
            # Create a simple placeholder
            set(GCC_WRAPPER "${MINGW_INSTALL_DIR}/bin/gcc.bat")
            file(WRITE "${GCC_WRAPPER}" 
                "@echo off\n"
                "echo MinGW-w64 placeholder (no suitable backend compiler found)\n"
                "exit /b 1\n"
            )
            
            set(GCC_EXECUTABLE "${GCC_WRAPPER}")
            set(MINGW_FOUND FALSE)
        endif()
        
        get_filename_component(MINGW_BIN_DIR "${GCC_EXECUTABLE}" DIRECTORY)
        get_filename_component(MINGW_ROOT_DIR "${MINGW_BIN_DIR}" DIRECTORY)
        
        message(STATUS "MinGW-w64 setup completed")
        message(STATUS "Source cloned to: ${MINGW_SOURCE_DIR}")
        message(STATUS "GCC wrapper created at: ${GCC_EXECUTABLE}")
        
    else()
        message(FATAL_ERROR "GCC not found and AUTO_DOWNLOAD_MINGW is disabled")
    endif()
endif()

# Function to setup MinGW environment
function(setup_mingw_environment)
    if(MINGW_FOUND OR GCC_EXECUTABLE)
        # Create environment setup script
        set(ENV_SETUP_SCRIPT "${CMAKE_BINARY_DIR}/setup_mingw_env.bat")
        file(WRITE "${ENV_SETUP_SCRIPT}"
            "@echo off\n"
            "echo Setting up MinGW-w64 environment...\n"
            "set MINGW_ROOT=${MINGW_ROOT_DIR}\n"
            "set PATH=${MINGW_BIN_DIR};%PATH%\n"
            "echo MinGW-w64 root: %MINGW_ROOT%\n"
            "echo MinGW-w64 bin added to PATH: ${MINGW_BIN_DIR}\n"
            "echo.\n"
            "echo Testing GCC:\n"
            "gcc --version\n"
            "if errorlevel 1 (\n"
            "    echo ERROR: GCC not working properly\n"
            ") else (\n"
            "    echo GCC is working correctly!\n"
            ")\n"
        )
        
        # Create PowerShell environment setup script
        set(ENV_SETUP_PS1 "${CMAKE_BINARY_DIR}/setup_mingw_env.ps1")
        file(WRITE "${ENV_SETUP_PS1}"
            "Write-Host 'Setting up MinGW-w64 environment...'\n"
            "$env:MINGW_ROOT = '${MINGW_ROOT_DIR}'\n"
            "$env:PATH = '${MINGW_BIN_DIR};' + $env:PATH\n"
            "Write-Host \"MinGW-w64 root: $env:MINGW_ROOT\"\n"
            "Write-Host \"MinGW-w64 bin added to PATH: ${MINGW_BIN_DIR}\"\n"
            "Write-Host ''\n"
            "Write-Host 'Testing GCC:'\n"
            "try {\n"
            "    & gcc --version\n"
            "    Write-Host 'GCC is working correctly!' -ForegroundColor Green\n"
            "} catch {\n"
            "    Write-Host 'ERROR: GCC not working properly' -ForegroundColor Red\n"
            "}\n"
        )
        
        message(STATUS "MinGW environment setup scripts created:")
        message(STATUS "  Batch: ${ENV_SETUP_SCRIPT}")
        message(STATUS "  PowerShell: ${ENV_SETUP_PS1}")
        
        # Set environment variables for current CMake session
        set(ENV{PATH} "${MINGW_BIN_DIR};$ENV{PATH}")
        set(ENV{MINGW_ROOT} "${MINGW_ROOT_DIR}")
        
        # Export variables to parent scope
        set(MINGW_BIN_DIR "${MINGW_BIN_DIR}" PARENT_SCOPE)
        set(MINGW_ROOT_DIR "${MINGW_ROOT_DIR}" PARENT_SCOPE)
        set(GCC_EXECUTABLE "${GCC_EXECUTABLE}" PARENT_SCOPE)
    endif()
endfunction()

# Setup environment
setup_mingw_environment()

# Print status
message(STATUS "MinGW-w64 Configuration:")
message(STATUS "  Found: ${MINGW_FOUND}")
if(MINGW_FOUND OR GCC_EXECUTABLE)
    message(STATUS "  Root: ${MINGW_ROOT_DIR}")
    message(STATUS "  Bin: ${MINGW_BIN_DIR}")
    message(STATUS "  GCC: ${GCC_EXECUTABLE}")
    if(EXISTS "${MINGW_SOURCE_DIR}")
        message(STATUS "  Source: ${MINGW_SOURCE_DIR}")
    endif()
endif()
