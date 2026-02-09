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
    tests/minder-regress
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
    initialize
    ninja io.github.phase1geo.minder-pot
    ninja io.github.phase1geo.minder-update-po
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
    ./io.github.phase1geo.minder "${@:2}"
    ;;
"run-flatpak")
    flatpak run io.github.phase1geo.minder "${@:2}"
    ;;
"debug")
    initialize
    # G_DEBUG=fatal-criticals gdb --args ./io.github.phase1geo.minder "${@:2}"
    G_DEBUG=fatal-warnings gdb --args ./io.github.phase1geo.minder "${@:2}"
    ;;
"heaptrack")
    initialize
    heaptrack ./io.github.phase1geo.minder "${@:2}"
    ;;
"valgrind")
    initialize
    valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes --num-callers=30 ./io.github.phase1geo.minder "${0:2}" | tee ../valgrind.out
    ;;
"flatpak-debug")
    echo "Run command at prompt: G_DEBUG=fatal-criticals gdb /app/bin/io.github.phase1geo.minder"
    flatpak run --devel --command=sh io.github.phase1geo.minder
    ;;
"test")
    test
    ;;
"uninstall")
    initialize
    sudo ninja uninstall
    ;;
"elementary")
    flatpak-builder --user --install --force-clean ../build-minder-elementary elementary/io.github.phase1geo.minder.yml
    flatpak install --user --reinstall --assumeyes "$(pwd)/.flatpak-builder/cache" io.github.phase1geo.minder.Debug
    ;;
"flathub")
    flatpak-builder --user --install --force-clean ../build-minder-flathub flathub/io.github.phase1geo.minder.yml
    flatpak install --user --reinstall --assumeyes "$(pwd)/.flatpak-builder/cache" io.github.phase1geo.minder.Debug
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
    echo "  uninstall         Removes the application from the system (requires sudo)"
    echo "  flatpak           Builds and installs the Flatpak version of the application"
    ;;
esac
