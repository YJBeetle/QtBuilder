cmake_minimum_required(VERSION 3.16)

project(proj VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Quick)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(app
    Main.cpp
)

qt_add_qml_module(app
    URI proj
    VERSION 1.0
    QML_FILES Main.qml
)

target_link_libraries(app PRIVATE Qt6::Quick)
