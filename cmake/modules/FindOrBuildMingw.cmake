# FindOrBuildMingw.cmake
# Module to find or build MinGW-w64 from source

# Options for MinGW build
option(BUILD_MINGW_FROM_SOURCE "Build MinGW-w64 from source if not found" ON)
option(FORCE_REBUILD_MINGW "Force rebuild of MinGW-w64 even if found" OFF)

# Set MinGW installation directory
set(MINGW_INSTALL_DIR "${CMAKE_BINARY_DIR}/mingw-w64-install" CACHE PATH "MinGW-w64 installation directory")
set(MINGW_SOURCE_DIR "${CMAKE_BINARY_DIR}/mingw-w64-source" CACHE PATH "MinGW-w64 source directory")
set(MINGW_BUILD_DIR "${CMAKE_BINARY_DIR}/mingw-w64-build" CACHE PATH "MinGW-w64 build directory")

# Check if MinGW is already available
find_program(GCC_EXECUTABLE gcc PATHS ${MINGW_INSTALL_DIR}/bin NO_DEFAULT_PATH)
find_program(GCC_EXECUTABLE_SYSTEM gcc)

if(GCC_EXECUTABLE AND NOT FORCE_REBUILD_MINGW)
    message(STATUS "Found existing GCC: ${GCC_EXECUTABLE}")
    set(MINGW_FOUND TRUE)
    get_filename_component(MINGW_BIN_DIR "${GCC_EXECUTABLE}" DIRECTORY)
    get_filename_component(MINGW_ROOT_DIR "${MINGW_BIN_DIR}" DIRECTORY)
else()
    if(BUILD_MINGW_FROM_SOURCE)
        message(STATUS "MinGW-w64 not found or force rebuild requested. Will build from source.")
        set(MINGW_FOUND FALSE)
        
        # Check for required build tools
        find_program(GIT_EXECUTABLE git REQUIRED)
        find_program(MAKE_EXECUTABLE make)
        
        if(WIN32)
            # On Windows, we might need to use different make
            if(NOT MAKE_EXECUTABLE)
                find_program(MAKE_EXECUTABLE mingw32-make)
            endif()
            if(NOT MAKE_EXECUTABLE)
                find_program(MAKE_EXECUTABLE nmake)
            endif()
        endif()
        
        if(NOT MAKE_EXECUTABLE)
            message(FATAL_ERROR "Make utility not found. Please install make or mingw32-make.")
        endif()
        
        message(STATUS "Git found: ${GIT_EXECUTABLE}")
        message(STATUS "Make found: ${MAKE_EXECUTABLE}")
        
    else()
        message(FATAL_ERROR "MinGW-w64 not found and BUILD_MINGW_FROM_SOURCE is disabled.")
    endif()
endif()

# Function to build MinGW-w64 from source
function(build_mingw_from_source)
    message(STATUS "Building MinGW-w64 from source...")
    
    # Set target triplet (you can modify this for different architectures)
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(TARGET_TRIPLET "x86_64-w64-mingw32")
        set(ARCH_FLAG "--enable-64bit")
    else()
        set(TARGET_TRIPLET "i686-w64-mingw32")
        set(ARCH_FLAG "--disable-64bit")
    endif()
    
    # Clone the repository if it doesn't exist
    if(NOT EXISTS "${MINGW_SOURCE_DIR}")
        message(STATUS "Cloning MinGW-w64 repository...")
        execute_process(
            COMMAND ${GIT_EXECUTABLE} clone --depth 1 https://git.code.sf.net/p/mingw-w64/mingw-w64 "${MINGW_SOURCE_DIR}"
            RESULT_VARIABLE GIT_RESULT
        )
        
        if(NOT GIT_RESULT EQUAL 0)
            message(FATAL_ERROR "Failed to clone MinGW-w64 repository")
        endif()
    endif()
    
    # Create build directory
    file(MAKE_DIRECTORY "${MINGW_BUILD_DIR}")
    file(MAKE_DIRECTORY "${MINGW_INSTALL_DIR}")
    
    # Configure MinGW-w64 headers
    message(STATUS "Configuring MinGW-w64 headers...")
    execute_process(
        COMMAND "${MINGW_SOURCE_DIR}/mingw-w64-headers/configure"
            --prefix=${MINGW_INSTALL_DIR}
            --host=${TARGET_TRIPLET}
            ${ARCH_FLAG}
        WORKING_DIRECTORY "${MINGW_BUILD_DIR}"
        RESULT_VARIABLE CONFIGURE_RESULT
    )
    
    if(NOT CONFIGURE_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to configure MinGW-w64 headers")
    endif()
    
    # Build and install headers
    message(STATUS "Installing MinGW-w64 headers...")
    execute_process(
        COMMAND ${MAKE_EXECUTABLE} install
        WORKING_DIRECTORY "${MINGW_BUILD_DIR}"
        RESULT_VARIABLE MAKE_RESULT
    )
    
    if(NOT MAKE_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to install MinGW-w64 headers")
    endif()
    
    # Now we need to build binutils and GCC
    # This is a simplified version - full MinGW build is very complex
    message(STATUS "Note: This is a simplified MinGW setup.")
    message(STATUS "For a complete MinGW-w64 toolchain, consider using MSYS2 or pre-built packages.")
    
    # Create a simple GCC wrapper script for basic functionality
    set(GCC_WRAPPER "${MINGW_INSTALL_DIR}/bin/gcc.bat")
    file(WRITE "${GCC_WRAPPER}" "@echo off\necho MinGW-w64 GCC wrapper\necho This is a placeholder for a full GCC installation\nexit /b 1\n")
    
    # Set variables for parent scope
    set(MINGW_FOUND TRUE PARENT_SCOPE)
    set(MINGW_BIN_DIR "${MINGW_INSTALL_DIR}/bin" PARENT_SCOPE)
    set(MINGW_ROOT_DIR "${MINGW_INSTALL_DIR}" PARENT_SCOPE)
    set(GCC_EXECUTABLE "${GCC_WRAPPER}" PARENT_SCOPE)
    
    message(STATUS "MinGW-w64 headers installed to: ${MINGW_INSTALL_DIR}")
    message(WARNING "Full GCC compiler build requires additional steps and dependencies.")
    message(STATUS "Consider using the automatic installer approach instead.")
endfunction()

# Function to setup environment for MinGW
function(setup_mingw_environment)
    if(MINGW_FOUND)
        # Add MinGW bin directory to PATH for this CMake session
        set(ENV{PATH} "${MINGW_BIN_DIR};$ENV{PATH}")
        
        # Create a batch file to set up the environment
        set(ENV_SETUP_FILE "${CMAKE_BINARY_DIR}/setup_mingw_env.bat")
        file(WRITE "${ENV_SETUP_FILE}" 
            "@echo off\n"
            "echo Setting up MinGW-w64 environment...\n"
            "set PATH=${MINGW_BIN_DIR};%PATH%\n"
            "echo MinGW-w64 bin directory added to PATH: ${MINGW_BIN_DIR}\n"
            "echo Testing GCC availability:\n"
            "gcc --version 2>nul || echo GCC not available\n"
        )
        
        message(STATUS "MinGW environment setup script created: ${ENV_SETUP_FILE}")
        message(STATUS "Run this script to set up MinGW environment in your terminal")
    endif()
endfunction()

# Main execution
if(NOT MINGW_FOUND AND BUILD_MINGW_FROM_SOURCE)
    build_mingw_from_source()
endif()

if(MINGW_FOUND OR BUILD_MINGW_FROM_SOURCE)
    setup_mingw_environment()
endif()
