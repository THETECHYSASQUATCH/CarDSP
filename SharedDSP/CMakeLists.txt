cmake_minimum_required(VERSION 3.22)
project(CarDSPShared LANGUAGES CXX)

add_library(cardsp_shared INTERFACE)
target_include_directories(cardsp_shared INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/include)
target_compile_features(cardsp_shared INTERFACE cxx_std_20)

option(CARDSP_BUILD_TESTS "Build portable DSP tests" ON)
if(CARDSP_BUILD_TESTS)
    enable_testing()
    add_executable(cardsp_shared_smoke tests/biquad_smoke.cpp)
    target_link_libraries(cardsp_shared_smoke PRIVATE cardsp_shared)
    add_test(NAME cardsp_shared_smoke COMMAND cardsp_shared_smoke)
endif()
