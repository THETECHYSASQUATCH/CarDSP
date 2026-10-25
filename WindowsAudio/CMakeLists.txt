if(NOT WIN32)
    return()
endif()

add_executable(cardsp_windows_audio
    src/main.cpp src/device_notifications.cpp src/audio_device_manager.cpp
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


