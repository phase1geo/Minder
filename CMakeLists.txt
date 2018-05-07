# project name
project (com.github.phase1geo.minder)

# the oldest stable cmake version we support
cmake_minimum_required (VERSION 2.6)

# tell cmake where its modules can be found in our project directory
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/src)

# where we install data directory (if we have any)
set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")

# what to call that directory where we install data too
set (PKGDATADIR "${DATADIR}/com.github.phase1geo.minder")

set (EXEC_NAME "com.github.phase1geo.minder")
set (RELEASE_NAME "")
set (VERSION "0.1")
set (VERSION_INFO "")

# GSettings
include(GSettings)
add_schema( "data/com.github.phase1geo.minder.gschema.xml" )

# we're about to use pkgconfig to make sure dependencies are installed so let's find pkgconfig first
find_package(PkgConfig)

# now let's actually check for the required dependencies
pkg_check_modules(DEPS REQUIRED gtk+-3.0 gee-0.8 glib-2.0 granite libxml-2.0 unity plank)

add_definitions(${DEPS_CFLAGS})
link_libraries(${DEPS_LIBRARIES})
link_directories(${DEPS_LIBRARY_DIRS})

# make sure we have vala
find_package(Vala REQUIRED)

# make sure we use vala
include(ValaVersion)

# make sure it's the desired version of vala
ensure_vala_version("0.16" MINIMUM)

# files we want to compile
include(ValaPrecompile)
vala_precompile(VALA_C ${EXEC_NAME}
    src/Animator.vala
    src/animator/AnimatorAction.vala
    src/animator/AnimatorNodes.vala
    src/animator/AnimatorPan.vala
    src/animator/AnimatorPositions.vala
    src/animator/AnimatorScale.vala
    src/Application.vala
    src/Document.vala
    src/DrawArea.vala
    src/Layout.vala
    src/Layouts.vala
    src/layouts/LayoutDown.vala
    src/layouts/LayoutHorizontal.vala
    src/layouts/LayoutLeft.vala
    src/layouts/LayoutManual.vala
    src/layouts/LayoutRight.vala
    src/layouts/LayoutUp.vala
    src/layouts/LayoutVertical.vala
    src/MainWindow.vala
    src/MapInspector.vala
    src/Node.vala
    src/NodeInspector.vala
    src/NonrootNode.vala
    src/OPML.vala
    src/Partitioner.vala
    src/PDF.vala
    src/Print.vala
    src/RootNode.vala
    src/Theme.vala
    src/Themes.vala
    src/themes/ThemeDefault.vala
    src/themes/ThemeDark.vala
    src/UndoBuffer.vala
    src/UndoItem.vala
    src/undo_actions/UndoNodeAttach.vala
    src/undo_actions/UndoNodeDelete.vala
    src/undo_actions/UndoNodeDetach.vala
    src/undo_actions/UndoNodeFold.vala
    src/undo_actions/UndoNodeInsert.vala
    src/undo_actions/UndoNodeMove.vala
    src/undo_actions/UndoNodeName.vala
    src/undo_actions/UndoNodeNote.vala
    src/undo_actions/UndoNodeTask.vala
PACKAGES
    gtk+-3.0
    gee-0.8
    glib-2.0
    granite
    libxml-2.0
    unity
    plank
)

# tell cmake what to call the executable we just made
add_executable(${EXEC_NAME} ${VALA_C})

# install the binaries we just made
install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)

# install our .desktop file so the Applications menu will see it
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/com.github.phase1geo.minder.desktop DESTINATION ${DATADIR}/applications/)

# install our .appdata.xml file so AppCenter will see it
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/com.github.phase1geo.minder.appdata.xml DESTINATION ${DATADIR}/metainfo/)

# install custom icons
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/16/minder-task-none-symbolic.svg         DESTINATION ${DATADIR}/icons/hicolor/16x16/apps/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/16/minder-task-todo-symbolic.svg         DESTINATION ${DATADIR}/icons/hicolor/16x16/apps/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/16/minder-task-done-symbolic.svg         DESTINATION ${DATADIR}/icons/hicolor/16x16/apps/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/16/minder-detach-symbolic.svg            DESTINATION ${DATADIR}/icons/hicolor/16x16/apps/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/16/minder-layout-manual-symbolic.svg     DESTINATION ${DATADIR}/icons/hicolor/16x16/apps/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/16/minder-layout-vertical-symbolic.svg   DESTINATION ${DATADIR}/icons/hicolor/16x16/apps/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/16/minder-layout-horizontal-symbolic.svg DESTINATION ${DATADIR}/icons/hicolor/16x16/apps/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/16/minder-layout-left-symbolic.svg       DESTINATION ${DATADIR}/icons/hicolor/16x16/apps/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/16/minder-layout-right-symbolic.svg      DESTINATION ${DATADIR}/icons/hicolor/16x16/apps/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/16/minder-layout-up-symbolic.svg         DESTINATION ${DATADIR}/icons/hicolor/16x16/apps/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/16/minder-layout-down-symbolic.svg       DESTINATION ${DATADIR}/icons/hicolor/16x16/apps/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/scalable/com.github.phase1geo.minder.svg DESTINATION ${DATADIR}/icons/hicolor/16x16/apps/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/scalable/com.github.phase1geo.minder.svg DESTINATION ${DATADIR}/icons/hicolor/24x24/apps/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/scalable/com.github.phase1geo.minder.svg DESTINATION ${DATADIR}/icons/hicolor/32x32/apps/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/scalable/com.github.phase1geo.minder.svg DESTINATION ${DATADIR}/icons/hicolor/48x48/apps/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/scalable/com.github.phase1geo.minder.svg DESTINATION ${DATADIR}/icons/hicolor/64x64/apps/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/scalable/com.github.phase1geo.minder.svg DESTINATION ${DATADIR}/icons/hicolor/128x128/apps/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/scalable/com.github.phase1geo.minder.svg DESTINATION ${DATADIR}/icons/hicolor/16x16@2/apps/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/scalable/com.github.phase1geo.minder.svg DESTINATION ${DATADIR}/icons/hicolor/24x24@2/apps/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/scalable/com.github.phase1geo.minder.svg DESTINATION ${DATADIR}/icons/hicolor/32x32@2/apps/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/scalable/com.github.phase1geo.minder.svg DESTINATION ${DATADIR}/icons/hicolor/48x48@2/apps/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/scalable/com.github.phase1geo.minder.svg DESTINATION ${DATADIR}/icons/hicolor/64x64@2/apps/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/scalable/com.github.phase1geo.minder.svg DESTINATION ${DATADIR}/icons/hicolor/128x128@2/apps/)

# Translation files
set (GETTEXT_PACKAGE "${CMAKE_PROJECT_NAME}")
add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
add_subdirectory (po)
