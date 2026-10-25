cmake_minimum_required(VERSION 3.22)

project(CarDSP LANGUAGES CXX)

# Enable testing at the repository root.
enable_testing()

# Portable cross-platform DSP engine.
add_subdirectory(SharedDSP)

if(WIN32)
    add_subdirectory(WindowsAudio)
endif()
