cmake_minimum_required(VERSION 3.22)

project(CarDSP LANGUAGES CXX)

# Enable testing at the repository root.
enable_testing()

# Portable cross-platform DSP engine.
add_subdirectory(SharedDSP)

if(WIN32)
    add_subdirectory(WindowsAudio)
endif()

# ============================================================
# CarDSP Packaging - CPack
# ============================================================

set(CPACK_PACKAGE_NAME "CarDSP")
set(CPACK_PACKAGE_VENDOR "The Techy Sasquatch")
set(CPACK_PACKAGE_VERSION "0.1.0")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "CarDSP audio processing tools")

if(WIN32)
    set(CPACK_GENERATOR "ZIP")
elseif(UNIX AND NOT APPLE AND NOT ANDROID)
    set(CPACK_GENERATOR "DEB")
    set(CPACK_DEBIAN_PACKAGE_MAINTAINER "The Techy Sasquatch")
endif()

if(WIN32 OR (UNIX AND NOT APPLE AND NOT ANDROID))
    include(CPack)
endif()
