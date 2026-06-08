#!/bin/bash

font_preview() {
    local idx="$1"
    local spacer="$2"
    local mode="$3"

    [[ "$mode" == "type" ]] && { echo "header"; return; }
    
    local font
    if [[ $idx -ge 0 && $idx -le 2 ]]; then
        font=$(get_font_name "$idx")
    else
        # When on 'Back' or any other index, show current active style
        font="$CUR_FONT"
        [[ -z "$font" ]] && font="auto"
    fi

    # Force 'Promptify' fallback for visual completeness in previews
    local preview_name="${BANNER_NAME}"
    [[ -z "$preview_name" || "$preview_name" == " " ]] && preview_name="Promptify"

    bash "$INSTALL_DIR/assets/.draw" "$preview_name" "--no-sig" "--no-clear" "--no-civis" "--font" "$font" "--preview"
}

current_banner_preview() {
    local idx="$1"
    local spacer="$2"
    local mode="$3"

    [[ "$mode" == "type" ]] && { echo "header"; return; }
    
    local font_arg="std"
    [[ "$CUR_FONT" != "auto" && "$CUR_FONT" != "" ]] && font_arg="$CUR_FONT"
    
    local preview_name="${BANNER_NAME}"
    [[ -z "$preview_name" || "$preview_name" == " " ]] && preview_name="Promptify"

    bash "$INSTALL_DIR/assets/.draw" "$preview_name" "--no-sig" "--no-clear" "--no-civis" "--font" "$font_arg" "--preview"
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
