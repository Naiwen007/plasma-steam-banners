cmake_minimum_required(VERSION 3.16)

project(
    plasma-steam-banners
    VERSION 0.1
    LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Qml)

if(QT_KNOWN_POLICY_QTP0001)
    qt_policy(SET QTP0001 NEW)
endif()

set(QT_QML_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml")

add_subdirectory(processplugin)

# Install the Plasma widget while excluding files generated locally
# at runtime.
install(
    DIRECTORY
        contents/
    DESTINATION
        share/plasma/plasmoids/com.new.steambanners/contents

    PATTERN "logos" EXCLUDE
    PATTERN "heroes" EXCLUDE
    PATTERN "banners" EXCLUDE
    PATTERN "cache" EXCLUDE
    PATTERN "__pycache__" EXCLUDE
    PATTERN "*.pyc" EXCLUDE
    PATTERN "games.json" EXCLUDE
)

install(
    FILES
        metadata.json
    DESTINATION
        share/plasma/plasmoids/com.new.steambanners
)
