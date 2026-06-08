#!/bin/bash

# Font style mapping (Index <-> Name)
get_font_name() {
    case "$1" in
        0) echo "auto" ;;
        1) echo "shadow" ;;
        2) echo "std" ;;
        *) echo "auto" ;;
    esac
}

get_font_idx() {
    case "$1" in
        "auto")   echo 0 ;;
        "shadow") echo 1 ;;
        "std")    echo 2 ;;
        *)        echo 0 ;;
    esac
}

get_font_label() {
    case "$1" in
        0) echo "Default" ;;
        1) echo "Shadow (3D Shadow)" ;;
        2) echo "Simple (Standard)" ;;
        *) echo "Default" ;;
    esac
}
