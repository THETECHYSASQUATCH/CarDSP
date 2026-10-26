cmake_minimum_required(VERSION 3.21)

project(CarDSPDesktop VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.8 REQUIRED COMPONENTS Quick QuickControls2 QuickDialogs2 Multimedia)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(CarDSPDesktop
    Audio/AudioPlaybackEngine.cpp
    Audio/AudioPlaybackEngine.hpp
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



