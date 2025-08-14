cmake_minimum_required(VERSION 3.22)
project(CtypesgenDemo VERSION 1.0.0 LANGUAGES C)

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
    # Custom target to generate Python bindings using ctypesgen
    add_custom_target(python_bindings
        COMMAND ${Python3_EXECUTABLE} -m ctypesgen -o pydemolib.py -l $<TARGET_FILE:demolib> demolib.h
        DEPENDS demolib
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Generating Python bindings with ctypesgen"
    )
    
    # Custom target to run Python demo
    add_custom_target(run_python_demo
        COMMAND ${Python3_EXECUTABLE} demoapp.py
        DEPENDS python_bindings
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Running Python demo application"
    )
endif()

# Print build configuration
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Build shared libs: ${BUILD_SHARED_LIBS}")
message(STATUS "Install prefix: ${CMAKE_INSTALL_PREFIX}")
