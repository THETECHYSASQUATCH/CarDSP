cmake_minimum_required(VERSION 3.22)
project(CarDSPShared LANGUAGES CXX)

add_library(cardsp_shared INTERFACE)
target_include_directories(cardsp_shared INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/include)
target_compile_features(cardsp_shared INTERFACE cxx_std_20)

option(CARDSP_BUILD_TOOLS "Build the stereo PCM stream adapter" ON)
if(CARDSP_BUILD_TOOLS)
    add_executable(cardsp_process_pcm tools/process_pcm.cpp)
    target_link_libraries(cardsp_process_pcm PRIVATE cardsp_shared)
endif()

option(CARDSP_BUILD_TESTS "Build portable DSP tests" ON)
if(CARDSP_BUILD_TESTS)
    enable_testing()
    if(CARDSP_BUILD_TOOLS)
        find_package(Python3 COMPONENTS Interpreter)
        if(Python3_Interpreter_FOUND)
            add_test(NAME cardsp_pcm_adapter COMMAND ${Python3_EXECUTABLE}
                ${CMAKE_CURRENT_SOURCE_DIR}/tests/pcm_adapter_tests.py $<TARGET_FILE:cardsp_process_pcm>)
        endif()
    endif()
    # Existing smoke tests use assert, including calls that construct the chain.
    # Keep those checks active in Release builds too.
    if(MSVC)
        add_compile_options(/UNDEBUG)
    else()
        add_compile_options(-UNDEBUG)
    endif()


    add_executable(cardsp_crossover_tests tests/crossover_tests.cpp)
    target_link_libraries(cardsp_crossover_tests PRIVATE cardsp_shared)
    add_test(NAME cardsp_crossover_tests COMMAND cardsp_crossover_tests)
    add_executable(cardsp_alignment_polarity_tests tests/alignment_polarity_tests.cpp)
    target_link_libraries(cardsp_alignment_polarity_tests PRIVATE cardsp_shared)
    add_test(NAME cardsp_alignment_polarity_tests COMMAND cardsp_alignment_polarity_tests)
    add_executable(cardsp_routing_tests tests/routing_tests.cpp)
    target_link_libraries(cardsp_routing_tests PRIVATE cardsp_shared)
    add_test(NAME cardsp_routing_tests COMMAND cardsp_routing_tests)
    add_executable(cardsp_stereo_tests tests/stereo_processor_tests.cpp)
    target_link_libraries(cardsp_stereo_tests PRIVATE cardsp_shared)
    add_test(NAME cardsp_stereo_tests COMMAND cardsp_stereo_tests)

    add_executable(cardsp_shared_smoke tests/biquad_smoke.cpp)
    target_link_libraries(cardsp_shared_smoke PRIVATE cardsp_shared)
    add_test(NAME cardsp_shared_smoke COMMAND cardsp_shared_smoke)

    add_executable(cardsp_dsp_chain_smoke tests/dsp_chain_smoke.cpp)
    target_link_libraries(cardsp_dsp_chain_smoke PRIVATE cardsp_shared)
    add_test(NAME cardsp_dsp_chain_smoke COMMAND cardsp_dsp_chain_smoke)
endif()

# CarDSP portable PCM processing tool
if(CARDSP_BUILD_TOOLS)
    install(TARGETS cardsp_process_pcm
        RUNTIME DESTINATION bin
    )
endif()



