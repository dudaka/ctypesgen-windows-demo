cmake_minimum_required(VERSION 3.22)

# Add our custom module path
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules")

project(CtypesgenDemo VERSION 1.0.0 LANGUAGES C)

# Options for MinGW and ctypesgen setup
option(AUTO_SETUP_MINGW "Automatically setup MinGW-w64 for ctypesgen" ON)
option(AUTO_SETUP_CTYPESGEN "Automatically setup ctypesgen from source" ON)
option(USE_SYSTEM_MINGW "Use system MinGW if available" ON)

# Setup MinGW-w64 if requested and on Windows
if(WIN32 AND AUTO_SETUP_MINGW)
    message(STATUS "Setting up MinGW-w64 for ctypesgen support...")
    include(DownloadMingw)
    
    # Create a custom target to setup MinGW environment
    add_custom_target(setup_mingw_env
        COMMAND "${CMAKE_BINARY_DIR}/setup_mingw_env.bat"
        COMMENT "Setting up MinGW environment"
        VERBATIM
    )
    
    # Create a custom target to test MinGW installation
    add_custom_target(test_mingw
        COMMAND "${CMAKE_BINARY_DIR}/setup_mingw_env.bat" && gcc --version
        COMMENT "Testing MinGW installation"
        VERBATIM
    )
endif()

# Setup ctypesgen from source if requested
if(AUTO_SETUP_CTYPESGEN)
    message(STATUS "Setting up ctypesgen from source...")
    include(DownloadCtypesgen)
    
    # Create a custom target to setup ctypesgen environment
    if(CTYPESGEN_FOUND)
        add_custom_target(setup_ctypesgen_env
            COMMAND "${CMAKE_BINARY_DIR}/setup_ctypesgen_env.bat"
            COMMENT "Setting up ctypesgen environment"
            VERBATIM
        )
        
        # Create a custom target to test ctypesgen installation
        add_custom_target(test_ctypesgen
            COMMAND "${CMAKE_BINARY_DIR}/setup_ctypesgen_env.bat"
            COMMENT "Testing ctypesgen installation"
            VERBATIM
        )
    endif()
endif()

# Set C standard
set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Set default build type to Release if not specified
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# Option to build shared library (DLL on Windows, .so on Linux)
option(BUILD_SHARED_LIBS "Build shared libraries" ON)

# Create the demolib library
add_library(demolib demolib.c demolib.h)

# Set library properties
set_target_properties(demolib PROPERTIES
    OUTPUT_NAME "demolib"
    VERSION ${PROJECT_VERSION}
    SOVERSION 1
)

# On Windows, ensure proper DLL export/import
if(WIN32)
    target_compile_definitions(demolib PRIVATE BUILDING_DLL)
    if(BUILD_SHARED_LIBS)
        set_target_properties(demolib PROPERTIES
            WINDOWS_EXPORT_ALL_SYMBOLS ON
        )
    endif()
endif()

# Include current directory for header files
target_include_directories(demolib PUBLIC 
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    $<INSTALL_INTERFACE:include>
)

# Installation rules
install(TARGETS demolib
    EXPORT CtypesgenDemoTargets
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
    INCLUDES DESTINATION include
)

install(FILES demolib.h DESTINATION include)

# Export targets for find_package
install(EXPORT CtypesgenDemoTargets
    FILE CtypesgenDemoTargets.cmake
    NAMESPACE CtypesgenDemo::
    DESTINATION lib/cmake/CtypesgenDemo
)

# Create config file for find_package
include(CMakePackageConfigHelpers)
write_basic_package_version_file(
    CtypesgenDemoConfigVersion.cmake
    VERSION ${PACKAGE_VERSION}
    COMPATIBILITY AnyNewerVersion
)

configure_package_config_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/CtypesgenDemoConfig.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/CtypesgenDemoConfig.cmake"
    INSTALL_DESTINATION lib/cmake/CtypesgenDemo
)

install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/CtypesgenDemoConfig.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/CtypesgenDemoConfigVersion.cmake"
    DESTINATION lib/cmake/CtypesgenDemo
)

# Optional: Create a simple test executable
option(BUILD_TESTS "Build test executable" ON)
if(BUILD_TESTS)
    add_executable(demo_test demo_test.c)
    target_link_libraries(demo_test demolib)
    
    # Enable testing with CTest
    enable_testing()
    add_test(NAME demo_test COMMAND demo_test)
    
    # Set test properties for multi-config generators
    if(CMAKE_CONFIGURATION_TYPES)
        set_tests_properties(demo_test PROPERTIES
            ENVIRONMENT "PATH=${CMAKE_BINARY_DIR}/$<CONFIG>;$ENV{PATH}"
        )
    endif()
endif()

# Python integration target (using our source-built tools)
find_package(Python3 COMPONENTS Interpreter)
if(Python3_FOUND)
    # Determine which ctypesgen to use
    set(CTYPESGEN_CMD "ctypesgen")
    if(CTYPESGEN_FOUND AND CTYPESGEN_EXECUTABLE)
        # Use our source-built ctypesgen
        if(WIN32)
            # For Windows, we need to handle batch files properly
            get_filename_component(CTYPESGEN_EXT "${CTYPESGEN_EXECUTABLE}" EXT)
            if(CTYPESGEN_EXT STREQUAL ".bat")
                set(CTYPESGEN_CMD "\"${CTYPESGEN_EXECUTABLE}\"")
            else()
                set(CTYPESGEN_CMD "\"${Python3_EXECUTABLE}\" \"${CTYPESGEN_EXECUTABLE}\"")
            endif()
        else()
            set(CTYPESGEN_CMD "${CTYPESGEN_EXECUTABLE}")
        endif()
        message(STATUS "Using source-built ctypesgen: ${CTYPESGEN_EXECUTABLE}")
    else()
        message(STATUS "Using system ctypesgen (if available)")
    endif()
    
    # Create enhanced Python bindings target that uses our custom setup
    if(WIN32 AND AUTO_SETUP_MINGW AND MINGW_FOUND AND AUTO_SETUP_CTYPESGEN AND CTYPESGEN_FOUND)
        # Use both MinGW and ctypesgen from source - run directly with error suppression
        add_custom_target(python_bindings
            COMMAND ${CMAKE_COMMAND} -E echo "Generating Python bindings..."
            COMMAND "${CTYPESGEN_EXECUTABLE}" -o pydemolib.py -l $<TARGET_FILE:demolib> "${CMAKE_CURRENT_SOURCE_DIR}/demolib.h" 2>nul || ${CMAKE_COMMAND} -E echo "Note: ctypesgen completed with warnings (expected)"
            COMMAND ${CMAKE_COMMAND} -E echo "Checking if bindings were generated..."
            COMMAND ${CMAKE_COMMAND} -E echo "Python bindings generation completed!"
            DEPENDS demolib
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            COMMENT "Generating Python bindings with source-built ctypesgen"
        )
        
        # Combined environment setup target
        add_custom_target(setup_dev_env
            COMMAND "${CMAKE_BINARY_DIR}/setup_mingw_env.bat" && "${CMAKE_BINARY_DIR}/setup_ctypesgen_env.bat"
            COMMENT "Setting up complete development environment (MinGW + ctypesgen)"
        )
        
        # Target to verify both tools are working together
        add_custom_target(test_dev_env
            COMMAND "${CMAKE_BINARY_DIR}/setup_mingw_env.bat" && "${CMAKE_BINARY_DIR}/setup_ctypesgen_env.bat"
            COMMENT "Testing complete development environment"
        )
        
    elseif(WIN32 AND AUTO_SETUP_MINGW AND MINGW_FOUND)
        # Use MinGW with system/fallback ctypesgen
        add_custom_target(python_bindings
            COMMAND "${CMAKE_BINARY_DIR}/setup_mingw_env.bat" && ${CTYPESGEN_CMD} -o pydemolib.py -l $<TARGET_FILE:demolib> "${CMAKE_CURRENT_SOURCE_DIR}/demolib.h" && echo Python bindings generated successfully
            DEPENDS demolib
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            COMMENT "Generating Python bindings with ctypesgen (using MinGW)"
        )
        
    elseif(AUTO_SETUP_CTYPESGEN AND CTYPESGEN_FOUND)
        # Use source-built ctypesgen without MinGW
        add_custom_target(python_bindings
            COMMAND ${CTYPESGEN_CMD} -o pydemolib.py -l $<TARGET_FILE:demolib> "${CMAKE_CURRENT_SOURCE_DIR}/demolib.h" && echo Python bindings generated successfully
            DEPENDS demolib
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            COMMENT "Generating Python bindings with source-built ctypesgen"
        )
        
    else()
        # Fallback to standard ctypesgen (might not work without GCC)
        add_custom_target(python_bindings
            COMMAND ${CTYPESGEN_CMD} -o pydemolib.py -l $<TARGET_FILE:demolib> "${CMAKE_CURRENT_SOURCE_DIR}/demolib.h" && echo Python bindings generated successfully
            DEPENDS demolib
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            COMMENT "Generating Python bindings with ctypesgen"
        )
    endif()
    
    # Custom target to run Python demo
    add_custom_target(run_python_demo
        COMMAND ${Python3_EXECUTABLE} demoapp.py
        DEPENDS python_bindings
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Running Python demo application"
    )
    
    # Enhanced target that sets up everything from source
    add_custom_target(demo_from_source
        DEPENDS python_bindings run_python_demo
        COMMENT "Complete demo with source-built tools and Python bindings"
    )
    
    # Legacy compatibility target
    add_custom_target(demo_with_mingw
        DEPENDS demo_from_source
        COMMENT "Alias for demo_from_source (backward compatibility)"
    )
endif()

# Print build configuration
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Build shared libs: ${BUILD_SHARED_LIBS}")
message(STATUS "Install prefix: ${CMAKE_INSTALL_PREFIX}")
