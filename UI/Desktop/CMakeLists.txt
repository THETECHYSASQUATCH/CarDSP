cmake_minimum_required(VERSION 3.21)

project(CarDSPDesktop VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.8 REQUIRED COMPONENTS Quick QuickControls2 QuickDialogs2 Multimedia)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(CarDSPDesktop
    Audio/AudioPlaybackEngine.cpp
    Audio/AudioPlaybackEngine.hpp
    Audio/PlaybackOutput.cpp
    Audio/PlaybackOutput.hpp
    Audio/AudioFileDecoder.cpp
    Audio/AudioFileDecoder.hpp
    Audio/MicrophoneManager.cpp
    Audio/SpectrumAnalyzer.cpp
    Audio/SpectrumAnalyzer.hpp
    Audio/MicrophoneManager.hpp
    PresetManager.cpp
    PresetManager.hpp
    EqController.cpp
    EqController.hpp
    main.cpp
)

qt_add_qml_module(CarDSPDesktop
    URI CarDSP
    VERSION 1.0
    QML_FILES
        Main.qml
        EditableValue.qml
        Audio/SpectrumView.qml
)

target_link_libraries(CarDSPDesktop
    PRIVATE
        Qt6::Core
        Qt6::Quick
        Qt6::QuickControls2 Qt6::QuickDialogs2
        Qt6::Multimedia
)

set_target_properties(CarDSPDesktop PROPERTIES
    WIN32_EXECUTABLE FALSE
)
if(WIN32)
    target_sources(CarDSPDesktop PRIVATE CarDSP.rc)
endif()




target_include_directories(CarDSPDesktop PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/../../SharedDSP/include"
)

include(CTest)
if(BUILD_TESTING)
    add_executable(cardsp_playback_tests tests/playback_tests.cpp)
    target_include_directories(cardsp_playback_tests PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}"
        "${CMAKE_CURRENT_SOURCE_DIR}/../../SharedDSP/include")
    target_link_libraries(cardsp_playback_tests PRIVATE Qt6::Core)
    add_test(NAME playback_silent COMMAND cardsp_playback_tests)
    get_target_property(qt_qmake Qt6::qmake IMPORTED_LOCATION)
    get_filename_component(qt_bin "${qt_qmake}" DIRECTORY)
    find_program(QMLTESTRUNNER qmltestrunner HINTS "${qt_bin}")
    if(QMLTESTRUNNER)
        add_test(NAME editable_values COMMAND "${QMLTESTRUNNER}"
            -input "${CMAKE_CURRENT_SOURCE_DIR}/tests" -platform offscreen
            -o -,txt)
    endif()
endif()

# Platform-specific installation and deployment
if(ANDROID)
    install(TARGETS CarDSPDesktop LIBRARY DESTINATION lib)
else()
    install(TARGETS CarDSPDesktop RUNTIME DESTINATION bin)

    if(WIN32 OR APPLE)
        qt_generate_deploy_qml_app_script(
            TARGET CarDSPDesktop
            OUTPUT_SCRIPT desktop_deploy_script
            NO_UNSUPPORTED_PLATFORM_ERROR
        )
        install(SCRIPT ${desktop_deploy_script})
    endif()
endif()

# Android SDK compatibility
if(ANDROID)
    set_property(TARGET CarDSPDesktop PROPERTY QT_ANDROID_COMPILE_SDK_VERSION 36)
endif()
