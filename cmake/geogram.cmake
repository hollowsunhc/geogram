
if(NOT DEFINED GEOGRAM_SOURCE_DIR)
   set(GEOGRAM_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
endif()

if(EXISTS ${GEOGRAM_SOURCE_DIR}/CMakeOptions.txt)
   message(STATUS "Using local options file: ${GEOGRAM_SOURCE_DIR}/CMakeOptions.txt")
   include(${GEOGRAM_SOURCE_DIR}/CMakeOptions.txt)
endif()

# Make sure that VORPALINE_PLATFORM is defined
if(NOT VORPALINE_PLATFORM)
     if(WIN32)
        message(
           STATUS
           " Using Win-vs-generic (default),\n"
           " (if need be, use CMake variable VORPALINE_PLATFORM to override)."
        )
        set(VORPALINE_PLATFORM Win-vs-generic)
     else()
        message(FATAL_ERROR
           " CMake variable VORPALINE_PLATFORM is not defined.\n"
           " Please run configure.{sh,bat} to setup the build tree."
        )
     endif()
endif()

# Determine whether Geogram is built with Vorpaline
if("$ENV{GEOGRAM_WITH_VORPALINE}" STREQUAL "")
    if(IS_DIRECTORY ${GEOGRAM_SOURCE_DIR}/src/lib/vorpalib)
        set(GEOGRAM_WITH_VORPALINE ON)
    else()
        set(GEOGRAM_WITH_VORPALINE OFF)
    endif()
else()
# GEOGRAM_WITH_VORPALINE is defined in the environment, used its value
    set(GEOGRAM_WITH_VORPALINE $ENV{GEOGRAM_WITH_VORPALINE})
endif()

if ("${GEOGRAM_WITH_VORPALINE}" STREQUAL ON)
   message(STATUS "Configuring build for Geogram + Vorpaline")
   add_definitions(-DGEOGRAM_WITH_VORPALINE)
else()
   message(STATUS "Configuring build for standalone Geogram (without Vorpaline)")
endif()

if(GEOGRAM_WITH_HLBFGS)
   add_definitions(-DGEOGRAM_WITH_HLBFGS)
endif()

if(GEOGRAM_WITH_TETGEN)
   add_definitions(-DGEOGRAM_WITH_TETGEN)
endif()

if(GEOGRAM_WITH_TRIANGLE)
   add_definitions(-DGEOGRAM_WITH_TRIANGLE)
endif()

if(GEOGRAM_WITH_LUA)
   add_definitions(-DGEOGRAM_WITH_LUA)
endif()

# This test is there to keep CMake happy about unused variable CMAKE_BUILD_TYPE
if(CMAKE_BUILD_TYPE STREQUAL "")
endif()

##############################################################################

include(${GEOGRAM_SOURCE_DIR}/cmake/utilities.cmake)
include(${GEOGRAM_SOURCE_DIR}/cmake/platforms/${VORPALINE_PLATFORM}/config.cmake)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# Static versus dynamic builds
if(VORPALINE_BUILD_DYNAMIC)
    set(BUILD_SHARED_LIBS TRUE)
    # Object files in OBJECT libraries are compiled in static mode, even if
    # BUILD_SHARED_LIBS is true! We must set CMAKE_POSITION_INDEPENDENT_CODE
    # to force compilation in dynamic mode.
    set(CMAKE_POSITION_INDEPENDENT_CODE TRUE)
    add_definitions(-DGEO_DYNAMIC_LIBS)
else()
    set(BUILD_SHARED_LIBS FALSE)
endif()

##############################################################################

# Use CMAKE_CFG_INTDIR for multi-config generator subdirectories (like Debug, Release)
# This is a generator expression placeholder that CMake resolves correctly.
# For single-config, it's often just "." or empty.

# For paths intended for link_directories, we need them to be absolute or
# correctly relative to where the linker is run from.
# It's generally better to use target_link_directories with absolute paths
# or paths derived from target properties.

# We can define where libraries will be PLACED using CMAKE_LIBRARY_OUTPUT_DIRECTORY.
# The link_directories command should then point to these *output* locations.

set(geogram_actual_lib_output_dir "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}")
if(CMAKE_CFG_INTDIR AND NOT CMAKE_CFG_INTDIR STREQUAL ".")
   # For multi-config generators, CMAKE_LIBRARY_OUTPUT_DIRECTORY might not include the config
   # but the actual libraries land in <output_dir>/<config>.
   # CMAKE_RUNTIME_OUTPUT_DIRECTORY and CMAKE_ARCHIVE_OUTPUT_DIRECTORY already handle this.
   # If we are constructing a path for link_directories, we might need to add the config.
   # However, modern CMake often handles this if targets are linked.
   # Let's assume CMAKE_LIBRARY_OUTPUT_DIRECTORY is already config-aware if needed,
   # or that target linking will resolve paths correctly.
   # For direct link_directories, we might use:
   # set(geogram_link_lib_dir "${CMAKE_BINARY_DIR}/lib/${CMAKE_CFG_INTDIR}")
   # but CMAKE_LIBRARY_OUTPUT_DIRECTORY is usually the better source.
   # If CMAKE_LIBRARY_OUTPUT_DIRECTORY is just "${CMAKE_BINARY_DIR}/lib",
   # then for multi-config we need to append the config for link_directories.

   # Let's be more explicit for link_directories for multi-config
   if(CMAKE_GENERATOR_IS_MULTI_CONFIG)
      set(PROJECT_CONFIGURABLE_LIB_DIR "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/${CMAKE_CFG_INTDIR}")
   else()
      set(PROJECT_CONFIGURABLE_LIB_DIR "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}")
   endif()

else() # Single-config or CMAKE_CFG_INTDIR is "."
   set(PROJECT_CONFIGURABLE_LIB_DIR "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}")
endif()

##############################################################################

include_directories(${GEOGRAM_SOURCE_DIR}/src/lib)
include_directories(${GEOGRAM_SOURCE_DIR}/src/lib/geogram_gfx/third_party/)
link_directories("${PROJECT_CONFIGURABLE_LIB_DIR}")

# It's even better to avoid global link_directories and use
# target_link_directories(my_target PRIVATE "${PROJECT_CONFIGURABLE_LIB_DIR}")
# or even better, link against imported targets or targets built within the project.
# For example, if 'geogram' is a library target built by this project:
# target_link_libraries(vorpastat PRIVATE geogram)
# And CMake will figure out the library path for geogram.
# The global link_directories is an older practice.

##############################################################################
