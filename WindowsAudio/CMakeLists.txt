if(NOT WIN32)
    return()
endif()

add_executable(cardsp_windows_audio
    src/main.cpp src/device_notifications.cpp src/audio_device_manager.cpp
    src/output_endpoint_catalog.cpp
    src/wasapi_loopback_capture.cpp
)

target_include_directories(cardsp_windows_audio PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)
target_compile_features(cardsp_windows_audio PRIVATE cxx_std_20)

target_link_libraries(cardsp_windows_audio PRIVATE
    cardsp_shared
    ole32
    uuid
)

target_compile_definitions(cardsp_windows_audio PRIVATE
    UNICODE
    _UNICODE
    WIN32_LEAN_AND_MEAN
    NOMINMAX
)




add_executable(cardsp_capture_test
    src/capture_test.cpp
    src/wasapi_loopback_capture.cpp
)

target_compile_features(cardsp_capture_test PRIVATE cxx_std_20)

target_include_directories(cardsp_capture_test PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_link_libraries(cardsp_capture_test PRIVATE
    ole32
    uuid
)

target_compile_definitions(cardsp_capture_test PRIVATE
    UNICODE
    _UNICODE
    WIN32_LEAN_AND_MEAN
    NOMINMAX
)

add_executable(cardsp_capture_dsp_test
    src/capture_dsp_test.cpp
    src/wasapi_loopback_capture.cpp
)

target_compile_features(cardsp_capture_dsp_test PRIVATE cxx_std_20)

target_include_directories(cardsp_capture_dsp_test PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_link_libraries(cardsp_capture_dsp_test PRIVATE
    cardsp_shared
    ole32
    uuid
)

target_compile_definitions(cardsp_capture_dsp_test PRIVATE
    UNICODE
    _UNICODE
    WIN32_LEAN_AND_MEAN
    NOMINMAX
)


add_executable(cardsp_output_device_test
    src/output_device_test.cpp
    src/output_endpoint_catalog.cpp
)

target_include_directories(cardsp_output_device_test PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_link_libraries(cardsp_output_device_test PRIVATE
    ole32
)
