#!/bin/bash

font_preview() {
    local idx="$1"
    local spacer="$2"
    local mode="$3"

    [[ "$mode" == "type" ]] && { echo "header"; return; }
    
    if [[ $idx -eq 4 ]]; then
        bash "$INSTALL_DIR/assets/.draw" "Promptify" "--no-sig" "--no-clear" "--no-civis" "--font" "std"
        return
    fi

    local font
    case "$idx" in
        0) font="auto" ;;
        1) font="shadow" ;;
        2) font="big" ;;
        3) font="std" ;;
        *) return ;;
    esac

    bash "$INSTALL_DIR/assets/.draw" "$BANNER_NAME" "--no-sig" "--no-clear" "--no-civis" "--font" "$font"
}

theme_preview() {
    local idx="$1"
    local spacer="$2"
    local mode="$3"

    [[ "$mode" == "type" ]] && { echo "footer"; return; }
    [[ $idx -gt 4 ]] && return

    # Get theme colors from central repo
    read -r border tag <<< "$(get_theme_data "$idx")"
    
    local h_name="termux"
    local short_tag="${BANNER_NAME:-Promptify}"
    short_tag="${short_tag%% *}"
    
    local c_border="${ANSI_COLORS[$border]}"
    local c_tag="${ANSI_COLORS[$tag]}"
    local reset="${ANSI_COLORS[reset]}"

    echo -ne "${spacer}${c_border}┌─[\e[1;33madmin/${reset}${c_tag}${short_tag}${reset}@\e[1;32m${h_name}${reset}${c_border}]─[\e[1;32m~${reset}${c_border}]${reset}\e[K"
    echo -e "\n${spacer}${c_border}└──╼ \e[1;31m❯\e[1;34m❯\e[1;30m❯${reset} \e[K"
}
