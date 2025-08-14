# DownloadCtypesgen.cmake
# CMake module to download and setup ctypesgen from GitHub source
# Similar to DownloadMingw.cmake but for ctypesgen

cmake_minimum_required(VERSION 3.22)

# Variables for ctypesgen setup
set(CTYPESGEN_SOURCE_DIR "${CMAKE_BINARY_DIR}/ctypesgen-source")
set(CTYPESGEN_INSTALL_DIR "${CMAKE_BINARY_DIR}/ctypesgen")
set(CTYPESGEN_EXECUTABLE "${CTYPESGEN_INSTALL_DIR}/bin/ctypesgen")

# Check for force rebuild option
option(FORCE_REBUILD_CTYPESGEN "Force rebuild ctypesgen from source" OFF)
option(AUTO_SETUP_CTYPESGEN "Automatically setup ctypesgen from source" ON)

# Function to check if ctypesgen is already available
function(find_system_ctypesgen)
    # First check if ctypesgen is available in PATH
    find_program(SYSTEM_CTYPESGEN_EXECUTABLE ctypesgen)
    
    if(SYSTEM_CTYPESGEN_EXECUTABLE)
        # Test if it works
        execute_process(
            COMMAND "${SYSTEM_CTYPESGEN_EXECUTABLE}" --version
            RESULT_VARIABLE CTYPESGEN_TEST_RESULT
            OUTPUT_VARIABLE CTYPESGEN_VERSION_OUTPUT
            ERROR_QUIET
        )
        
        if(CTYPESGEN_TEST_RESULT EQUAL 0)
            message(STATUS "Found system ctypesgen: ${SYSTEM_CTYPESGEN_EXECUTABLE}")
            message(STATUS "ctypesgen version: ${CTYPESGEN_VERSION_OUTPUT}")
            set(CTYPESGEN_FOUND TRUE PARENT_SCOPE)
            set(CTYPESGEN_EXECUTABLE "${SYSTEM_CTYPESGEN_EXECUTABLE}" PARENT_SCOPE)
            return()
        endif()
    endif()
    
    # Check if our custom installation exists
    if(EXISTS "${CTYPESGEN_EXECUTABLE}")
        execute_process(
            COMMAND "${Python3_EXECUTABLE}" "${CTYPESGEN_EXECUTABLE}" --version
            RESULT_VARIABLE CTYPESGEN_TEST_RESULT
            OUTPUT_VARIABLE CTYPESGEN_VERSION_OUTPUT
            ERROR_QUIET
        )
        
        if(CTYPESGEN_TEST_RESULT EQUAL 0)
            message(STATUS "Found custom ctypesgen: ${CTYPESGEN_EXECUTABLE}")
            set(CTYPESGEN_FOUND TRUE PARENT_SCOPE)
            return()
        endif()
    endif()
    
    set(CTYPESGEN_FOUND FALSE PARENT_SCOPE)
endfunction()

# Function to clone ctypesgen from GitHub
function(clone_ctypesgen_source)
    # Check if Git is available
    find_package(Git REQUIRED)
    
    if(NOT Git_FOUND)
        message(FATAL_ERROR "Git is required to clone ctypesgen source. Please install Git.")
    endif()
    
    # Clone or update ctypesgen source
    if(NOT EXISTS "${CTYPESGEN_SOURCE_DIR}" OR FORCE_REBUILD_CTYPESGEN)
        if(EXISTS "${CTYPESGEN_SOURCE_DIR}")
            message(STATUS "Removing existing ctypesgen source for rebuild...")
            file(REMOVE_RECURSE "${CTYPESGEN_SOURCE_DIR}")
        endif()
        
        message(STATUS "Cloning ctypesgen from GitHub...")
        execute_process(
            COMMAND "${GIT_EXECUTABLE}" clone https://github.com/ctypesgen/ctypesgen.git "${CTYPESGEN_SOURCE_DIR}"
            RESULT_VARIABLE GIT_RESULT
            OUTPUT_VARIABLE GIT_OUTPUT
            ERROR_VARIABLE GIT_ERROR
        )
        
        if(NOT GIT_RESULT EQUAL 0)
            message(FATAL_ERROR "Failed to clone ctypesgen: ${GIT_ERROR}")
        endif()
        
        message(STATUS "ctypesgen cloned successfully to: ${CTYPESGEN_SOURCE_DIR}")
    else()
        message(STATUS "ctypesgen source already exists at: ${CTYPESGEN_SOURCE_DIR}")
    endif()
endfunction()

# Function to install ctypesgen from source
function(install_ctypesgen_from_source)
    # Ensure Python is available
    if(NOT Python3_FOUND)
        message(FATAL_ERROR "Python3 is required to install ctypesgen")
    endif()
    
    # Create installation directory
    file(MAKE_DIRECTORY "${CTYPESGEN_INSTALL_DIR}")
    file(MAKE_DIRECTORY "${CTYPESGEN_INSTALL_DIR}/bin")
    
    # Install ctypesgen using pip in development mode
    message(STATUS "Installing ctypesgen from source...")
    execute_process(
        COMMAND "${Python3_EXECUTABLE}" -m pip install -e "${CTYPESGEN_SOURCE_DIR}" --prefix "${CTYPESGEN_INSTALL_DIR}"
        RESULT_VARIABLE PIP_RESULT
        OUTPUT_VARIABLE PIP_OUTPUT
        ERROR_VARIABLE PIP_ERROR
        WORKING_DIRECTORY "${CTYPESGEN_SOURCE_DIR}"
    )
    
    if(NOT PIP_RESULT EQUAL 0)
        message(STATUS "pip install failed, trying alternative installation...")
        
        # Alternative: install using setup.py
        execute_process(
            COMMAND "${Python3_EXECUTABLE}" setup.py install --prefix "${CTYPESGEN_INSTALL_DIR}"
            RESULT_VARIABLE SETUP_RESULT
            OUTPUT_VARIABLE SETUP_OUTPUT
            ERROR_VARIABLE SETUP_ERROR
            WORKING_DIRECTORY "${CTYPESGEN_SOURCE_DIR}"
        )
        
        if(NOT SETUP_RESULT EQUAL 0)
            message(STATUS "setup.py install failed, creating direct script wrapper...")
            
            # Create a simple wrapper script
            if(WIN32)
                set(CTYPESGEN_WRAPPER "${CTYPESGEN_INSTALL_DIR}/bin/ctypesgen.bat")
                file(WRITE "${CTYPESGEN_WRAPPER}"
                    "@echo off\n"
                    "REM ctypesgen wrapper script\n"
                    "\"${Python3_EXECUTABLE}\" \"${CTYPESGEN_SOURCE_DIR}/ctypesgen/__main__.py\" %*\n"
                )
                set(CTYPESGEN_EXECUTABLE "${CTYPESGEN_WRAPPER}" PARENT_SCOPE)
            else()
                set(CTYPESGEN_WRAPPER "${CTYPESGEN_INSTALL_DIR}/bin/ctypesgen")
                file(WRITE "${CTYPESGEN_WRAPPER}"
                    "#!/bin/bash\n"
                    "# ctypesgen wrapper script\n"
                    "\"${Python3_EXECUTABLE}\" \"${CTYPESGEN_SOURCE_DIR}/ctypesgen/__main__.py\" \"$@\"\n"
                )
                execute_process(COMMAND chmod +x "${CTYPESGEN_WRAPPER}")
                set(CTYPESGEN_EXECUTABLE "${CTYPESGEN_WRAPPER}" PARENT_SCOPE)
            endif()
            
            message(STATUS "Created ctypesgen wrapper: ${CTYPESGEN_WRAPPER}")
        else()
            message(STATUS "ctypesgen installed successfully using setup.py")
        endif()
    else()
        message(STATUS "ctypesgen installed successfully using pip")
    endif()
endfunction()

# Function to setup ctypesgen environment
function(setup_ctypesgen_environment)
    if(CTYPESGEN_FOUND OR CTYPESGEN_EXECUTABLE)
        # Create environment setup script
        set(CTYPESGEN_ENV_SETUP_SCRIPT "${CMAKE_BINARY_DIR}/setup_ctypesgen_env.bat")
        file(WRITE "${CTYPESGEN_ENV_SETUP_SCRIPT}"
            "@echo off\n"
            "echo Setting up ctypesgen environment...\n"
            "set CTYPESGEN_ROOT=${CTYPESGEN_INSTALL_DIR}\n"
            "set PATH=${CTYPESGEN_INSTALL_DIR}/bin;%PATH%\n"
            "echo ctypesgen root: %CTYPESGEN_ROOT%\n"
            "echo ctypesgen bin added to PATH: ${CTYPESGEN_INSTALL_DIR}/bin\n"
            "echo.\n"
            "echo Testing ctypesgen:\n"
            "call \"${CTYPESGEN_EXECUTABLE}\" --version\n"
            "if errorlevel 1 (\n"
            "    echo ERROR: ctypesgen not working properly\n"
            ") else (\n"
            "    echo ctypesgen is working correctly!\n"
            ")\n"
        )
        
        # Create PowerShell environment setup script
        set(CTYPESGEN_ENV_SETUP_PS1 "${CMAKE_BINARY_DIR}/setup_ctypesgen_env.ps1")
        file(WRITE "${CTYPESGEN_ENV_SETUP_PS1}"
            "Write-Host 'Setting up ctypesgen environment...'\n"
            "$env:CTYPESGEN_ROOT = '${CTYPESGEN_INSTALL_DIR}'\n"
            "$env:PATH = '${CTYPESGEN_INSTALL_DIR}/bin;' + $env:PATH\n"
            "Write-Host \"ctypesgen root: $env:CTYPESGEN_ROOT\"\n"
            "Write-Host \"Testing ctypesgen...\"\n"
            "& '${Python3_EXECUTABLE}' '${CTYPESGEN_EXECUTABLE}' --version\n"
            "if ($LASTEXITCODE -eq 0) {\n"
            "    Write-Host 'ctypesgen is working correctly!' -ForegroundColor Green\n"
            "} else {\n"
            "    Write-Host 'ERROR: ctypesgen not working properly' -ForegroundColor Red\n"
            "}\n"
        )
        
        message(STATUS "ctypesgen environment setup scripts created:")
        message(STATUS "  Batch: ${CTYPESGEN_ENV_SETUP_SCRIPT}")
        message(STATUS "  PowerShell: ${CTYPESGEN_ENV_SETUP_PS1}")
    endif()
endfunction()

# Main logic
if(AUTO_SETUP_CTYPESGEN)
    # Find Python first
    find_package(Python3 REQUIRED COMPONENTS Interpreter)
    
    # Check if ctypesgen is already available
    find_system_ctypesgen()
    
    if(NOT CTYPESGEN_FOUND OR FORCE_REBUILD_CTYPESGEN)
        if(FORCE_REBUILD_CTYPESGEN)
            message(STATUS "Force rebuild requested - will create custom ctypesgen setup")
        else()
            message(STATUS "ctypesgen not found. Will clone from GitHub...")
        endif()
        
        # Clone ctypesgen source
        clone_ctypesgen_source()
        
        # Install ctypesgen from source
        install_ctypesgen_from_source()
        
        # Test the installation
        # Check multiple possible locations for the installed ctypesgen
        set(POSSIBLE_CTYPESGEN_PATHS
            "${CTYPESGEN_INSTALL_DIR}/bin/ctypesgen"
            "${CTYPESGEN_INSTALL_DIR}/bin/ctypesgen.exe"
            "${CTYPESGEN_INSTALL_DIR}/Scripts/ctypesgen"
            "${CTYPESGEN_INSTALL_DIR}/Scripts/ctypesgen.exe"
            "${CTYPESGEN_EXECUTABLE}"
        )
        
        set(CTYPESGEN_WORKING_EXECUTABLE "")
        foreach(POSSIBLE_PATH ${POSSIBLE_CTYPESGEN_PATHS})
            if(EXISTS "${POSSIBLE_PATH}")
                execute_process(
                    COMMAND "${Python3_EXECUTABLE}" "${POSSIBLE_PATH}" --version
                    RESULT_VARIABLE CTYPESGEN_TEST_RESULT
                    OUTPUT_VARIABLE CTYPESGEN_VERSION_OUTPUT
                    ERROR_QUIET
                )
                
                if(CTYPESGEN_TEST_RESULT EQUAL 0)
                    set(CTYPESGEN_WORKING_EXECUTABLE "${POSSIBLE_PATH}")
                    break()
                endif()
            endif()
        endforeach()
        
        if(CTYPESGEN_WORKING_EXECUTABLE)
            set(CTYPESGEN_EXECUTABLE "${CTYPESGEN_WORKING_EXECUTABLE}")
            set(CTYPESGEN_FOUND TRUE)
            message(STATUS "ctypesgen installation verified successfully")
            message(STATUS "Working executable: ${CTYPESGEN_EXECUTABLE}")
        else()
            # Try direct execution from source directory as a module
            execute_process(
                COMMAND "${Python3_EXECUTABLE}" -m ctypesgen --version
                RESULT_VARIABLE CTYPESGEN_MODULE_TEST_RESULT
                OUTPUT_VARIABLE CTYPESGEN_VERSION_OUTPUT
                ERROR_QUIET
                WORKING_DIRECTORY "${CTYPESGEN_SOURCE_DIR}"
            )
            
            if(CTYPESGEN_MODULE_TEST_RESULT EQUAL 0)
                # Create a wrapper that sets PYTHONPATH instead of changing directory
                if(WIN32)
                    set(CTYPESGEN_WRAPPER "${CTYPESGEN_INSTALL_DIR}/bin/ctypesgen.bat")
                    file(MAKE_DIRECTORY "${CTYPESGEN_INSTALL_DIR}/bin")
                    file(WRITE "${CTYPESGEN_WRAPPER}"
                        "@echo off\n"
                        "set ORIGINAL_PYTHONPATH=%PYTHONPATH%\n"
                        "set PYTHONPATH=${CTYPESGEN_SOURCE_DIR};%PYTHONPATH%\n"
                        "\"${Python3_EXECUTABLE}\" -m ctypesgen %*\n"
                        "set RESULT=%errorlevel%\n"
                        "set PYTHONPATH=%ORIGINAL_PYTHONPATH%\n"
                        "exit /b %RESULT%\n"
                    )
                    set(CTYPESGEN_EXECUTABLE "${CTYPESGEN_WRAPPER}")
                else()
                    set(CTYPESGEN_WRAPPER "${CTYPESGEN_INSTALL_DIR}/bin/ctypesgen")
                    file(MAKE_DIRECTORY "${CTYPESGEN_INSTALL_DIR}/bin")
                    file(WRITE "${CTYPESGEN_WRAPPER}"
                        "#!/bin/bash\n"
                        "export PYTHONPATH=\"${CTYPESGEN_SOURCE_DIR}:$PYTHONPATH\"\n"
                        "\"${Python3_EXECUTABLE}\" -m ctypesgen \"$@\"\n"
                    )
                    execute_process(COMMAND chmod +x "${CTYPESGEN_WRAPPER}")
                    set(CTYPESGEN_EXECUTABLE "${CTYPESGEN_WRAPPER}")
                endif()
                
                set(CTYPESGEN_FOUND TRUE)
                message(STATUS "ctypesgen verified as Python module from source")
                message(STATUS "Created wrapper: ${CTYPESGEN_EXECUTABLE}")
            else()
                message(WARNING "ctypesgen module test failed")
                set(CTYPESGEN_FOUND FALSE)
            endif()
        endif()
        
        # Setup environment
        setup_ctypesgen_environment()
        
        message(STATUS "ctypesgen setup completed")
        message(STATUS "Source cloned to: ${CTYPESGEN_SOURCE_DIR}")
        message(STATUS "ctypesgen installed to: ${CTYPESGEN_INSTALL_DIR}")
        message(STATUS "ctypesgen executable: ${CTYPESGEN_EXECUTABLE}")
        
    else()
        message(STATUS "Using existing ctypesgen installation")
        setup_ctypesgen_environment()
    endif()
endif()

# Export variables for use in main CMakeLists.txt
set(CTYPESGEN_FOUND ${CTYPESGEN_FOUND} CACHE BOOL "Whether ctypesgen was found")
set(CTYPESGEN_EXECUTABLE ${CTYPESGEN_EXECUTABLE} CACHE STRING "Path to ctypesgen executable")
set(CTYPESGEN_SOURCE_DIR ${CTYPESGEN_SOURCE_DIR} CACHE STRING "Path to ctypesgen source directory")
set(CTYPESGEN_INSTALL_DIR ${CTYPESGEN_INSTALL_DIR} CACHE STRING "Path to ctypesgen install directory")

# Print configuration summary
if(CTYPESGEN_FOUND)
    message(STATUS "ctypesgen Configuration:")
    message(STATUS "  Found: TRUE")
    message(STATUS "  Executable: ${CTYPESGEN_EXECUTABLE}")
    message(STATUS "  Source: ${CTYPESGEN_SOURCE_DIR}")
    message(STATUS "  Install: ${CTYPESGEN_INSTALL_DIR}")
else()
    message(STATUS "ctypesgen Configuration:")
    message(STATUS "  Found: FALSE")
endif()
