#!/bin/bash

# Bundled figlet fonts shipped with Promptify (single source of truth).
# Sourced before install/ui/maintenance modules, so it is visible everywhere.
BUNDLED_FONTS=("ASCII-Shadow.flf" "slant.flf" "banner.flf" "smpoison.flf" "graffiti.flf")

# Font style mapping (Index <-> Name)
get_font_name() {
    case "$1" in
        0) echo "random" ;;
        1) echo "shadow" ;;
        2) echo "std" ;;
        3) echo "slant" ;;
        4) echo "banner" ;;
        5) echo "smpoison" ;;
        6) echo "graffiti" ;;
        *) echo "random" ;;
    esac
}

get_font_idx() {
    case "$1" in
        "random")   echo 0 ;;
        "auto")     echo 0 ;;
        "shadow")   echo 1 ;;
        "std")      echo 2 ;;
        "slant")    echo 3 ;;
        "banner")   echo 4 ;;
        "smpoison") echo 5 ;;
        "graffiti") echo 6 ;;
        *)          echo 0 ;;
    esac
}

get_font_label() {
    case "$1" in
        0) echo "Random" ;;
        1) echo "Shadow" ;;
        2) echo "Simple" ;;
        3) echo "Slant" ;;
        4) echo "Banner" ;;
        5) echo "Poison" ;;
        6) echo "Graffiti" ;;
        *) echo "Random" ;;
    esac
}
