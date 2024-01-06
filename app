#!/bin/bash

arg=$1

function initialize {
    meson setup build --prefix=/usr
    result=$?

    if [ $result -gt 0 ]; then
        echo "Unable to initialize, please review log"
        exit 1
    fi

    cd build

    ninja

    result=$?

    if [ $result -gt 0 ]; then
        echo "Unable to build project, please review log"
        exit 2
    fi
}

function test {
    initialize

    export DISPLAY=:0
    ./com.github.phase1geo.minder --run-tests
    result=$?

    export DISPLAY=":0.0"

    echo ""
    if [ $result -gt 0 ]; then
        echo "Failed testing"
        exit 100
    fi

    echo "Tests passed!"
}

case $1 in
"clean")
    sudo rm -rf ./build
    ;;
"generate-i18n")
    grep -rc _\( * | grep ^src | grep -v :0 | cut -d : -f 1 | sort -o po/POTFILES
    echo "data/com.github.phase1geo.minder.shortcuts.ui" >> po/POTFILES
    initialize
    ninja com.github.phase1geo.minder-pot
    ninja com.github.phase1geo.minder-update-po
    ninja extra-pot
    ninja extra-update-po
    cp data/* ../data
    ;;
"install")
    initialize
    sudo ninja install
    ;;
"install-deps")
    output=$((dpkg-checkbuilddeps ) 2>&1)
    result=$?

    if [ $result -eq 0 ]; then
        echo "All dependencies are installed"
        exit 0
    fi

    replace="sudo apt install"
    pattern="(\([>=<0-9. ]+\))+"
    sudo_replace=${output/dpkg-checkbuilddeps: error: Unmet build dependencies:/$replace}
    command=$(sed -r -e "s/$pattern//g" <<< "$sudo_replace")
    
    $command
    ;;
"run")
    initialize
    ./com.github.phase1geo.minder "${@:2}"
    ;;
"run-flatpak")
    flatpak run com.github.phase1geo.minder
    ;;
"debug")
    initialize
    G_DEBUG=fatal-criticals gdb --args ./com.github.phase1geo.minder "${@:2}"
    # G_DEBUG=fatal-warnings gdb --args ./com.github.phase1geo.minder "${@:2}"
    ;;
"flatpak-debug")
    echo "Run command at prompt: G_DEBUG=fatal-criticals gdb /app/bin/com.github.phase1geo.minder"
    flatpak run --devel --command=sh com.github.phase1geo.minder
    ;;
"test")
    test
    ;;
"test-run")
    test
    ./com.github.phase1geo.minder "${@:2}"
    ;;
"uninstall")
    initialize
    sudo ninja uninstall
    ;;
"flatpak")
    flatpak-builder --user --install --force-clean ../build-minder com.github.phase1geo.minder.yml
    flatpak install --user --reinstall --assumeyes "$(pwd)/.flatpak-builder/cache" com.github.phase1geo.minder.Debug
    ;;
*)
    echo "Usage:"
    echo "  ./app [OPTION]"
    echo ""
    echo "Options:"
    echo "  clean             Removes build directories (can require sudo)"
    echo "  generate-i18n     Generates .pot and .po files for i18n (multi-language support)"
    echo "  install           Builds and installs application to the system (requires sudo)"
    echo "  install-deps      Installs missing build dependencies"
    echo "  run               Builds and runs the application (must run install once before successive calls to this command)"
    echo "  test              Builds and runs testing for the application"
    echo "  test-run          Builds application, runs testing and if successful application is started"
    echo "  uninstall         Removes the application from the system (requires sudo)"
    echo "  flatpak           Builds and installs the Flatpak version of the application"
    ;;
esac
