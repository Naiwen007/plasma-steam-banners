qt_add_qml_module(steambanners_processplugin
    URI SteamBanners.Process
    VERSION 1.0

    SOURCES
        process.cpp
        process.h
)

target_link_libraries(
    steambanners_processplugin
    PRIVATE
        Qt6::Core
        Qt6::Qml
)

# Query the files generated for this QML module.
qt_query_qml_module(
    steambanners_processplugin

    PLUGIN_TARGET qml_plugin_target
    TARGET_PATH qml_target_path
    QMLDIR qml_qmldir
    TYPEINFO qml_typeinfo
)

set_target_properties(
    ${qml_plugin_target}
    PROPERTIES
        INSTALL_RPATH "$ORIGIN"
)

# User-local Qt QML path when using:
#
#   cmake --install build --prefix ~/.local
#
set(
    QML_INSTALL_DIR
    "lib/qt6/qml/${qml_target_path}"
)

install(
    TARGETS
        steambanners_processplugin
    LIBRARY DESTINATION "${QML_INSTALL_DIR}"
)

if(qml_plugin_target)
    install(
        TARGETS
            ${qml_plugin_target}
        LIBRARY DESTINATION "${QML_INSTALL_DIR}"
    )
endif()

install(
    FILES
        "${qml_qmldir}"
        "${qml_typeinfo}"
    DESTINATION
        "${QML_INSTALL_DIR}"
)
