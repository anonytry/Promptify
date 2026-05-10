#!/bin/bash

# Theme definitions (Index -> Border Color | Tag Color)
get_theme_data() {
    local idx="$1"
    case "$idx" in
        0) echo "cyan blue" ;;
        1) echo "magenta cyan" ;;
        2) echo "green green" ;;
        3) echo "yellow white" ;;
        4) echo "red blue" ;;
        *) echo "red blue" ;; # Default
    esac
}

# Color ANSI Map
# shellcheck disable=SC2034
declare -A ANSI_COLORS=(
    ["red"]="\e[1;31m"
    ["green"]="\e[1;32m"
    ["yellow"]="\e[1;33m"
    ["blue"]="\e[1;34m"
    ["magenta"]="\e[1;35m"
    ["cyan"]="\e[1;36m"
    ["white"]="\e[1;37m"
    ["reset"]="\e[0m"
)
