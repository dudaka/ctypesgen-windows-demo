cmake_minimum_required(VERSION 3.22)

# Add our custom module path
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules")

project(CtypesgenDemo VERSION 1.0.0 LANGUAGES C)

# Options for MinGW setup
option(AUTO_SETUP_MINGW "Automatically setup MinGW-w64 for ctypesgen" ON)
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

# Python integration target (optional)
find_package(Python3 COMPONENTS Interpreter)
if(Python3_FOUND)
    # Create enhanced Python bindings target that uses our MinGW setup
    if(WIN32 AND AUTO_SETUP_MINGW AND MINGW_FOUND)
        # Use MinGW environment for ctypesgen
        add_custom_target(python_bindings
            COMMAND "${CMAKE_BINARY_DIR}/setup_mingw_env.bat" && ctypesgen -o pydemolib.py -l $<TARGET_FILE:demolib> demolib.h
            DEPENDS demolib
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            COMMENT "Generating Python bindings with ctypesgen (using MinGW)"
        )
        
        # Target to verify MinGW is working for ctypesgen
        add_custom_target(test_ctypesgen_mingw
            COMMAND "${CMAKE_BINARY_DIR}/setup_mingw_env.bat" && ${Python3_EXECUTABLE} -c "import subprocess; subprocess.run(['gcc', '--version'], check=True)"
            COMMENT "Testing if ctypesgen can access GCC"
        )
    else()
        # Fallback to standard ctypesgen (might not work without GCC)
        add_custom_target(python_bindings
            COMMAND ctypesgen -o pydemolib.py -l $<TARGET_FILE:demolib> demolib.h
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
    
    # Enhanced target that sets up everything
    add_custom_target(demo_with_mingw
        DEPENDS python_bindings run_python_demo
        COMMENT "Complete demo with MinGW setup and Python bindings"
    )
endif()

# Print build configuration
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Build shared libs: ${BUILD_SHARED_LIBS}")
message(STATUS "Install prefix: ${CMAKE_INSTALL_PREFIX}")
