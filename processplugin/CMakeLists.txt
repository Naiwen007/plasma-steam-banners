cmake_minimum_required(VERSION 3.16)

project(steambanners_processplugin LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Qml)

qt_add_qml_module(steambanners_processplugin
    URI SteamBanners.Process
    VERSION 1.0
    SOURCES
        process.cpp
        process.h
)

target_link_libraries(steambanners_processplugin
    PRIVATE
        Qt6::Core
        Qt6::Qml
)
