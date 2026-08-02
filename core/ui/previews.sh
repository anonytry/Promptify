#!/bin/bash

font_preview() {
    local idx="$1"
    local spacer="$2"
    local mode="$3"

    [[ "$mode" == "type" ]] && { echo "header"; return; }
    
    local font
    if [[ $idx -ge 0 && $idx -le 6 ]]; then
        font=$(get_font_name "$idx")
    else
        # When on 'Back' or any other index, show current active style
        font="$CUR_FONT"
        [[ -z "$font" ]] && font="random"
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

# Simulated bat output preview for the Cat Display Style menu. Renders a
# small sample file the way the selected style would display it, using the
# active theme colors. Footer-type preview (drawn under the menu options).
cat_preview() {
    local idx="$1"
    local spacer="$2"
    local mode="$3"

    [[ "$mode" == "type" ]] && { echo "footer"; return; }
    [[ $idx -gt 3 ]] && return

    local reset="${ANSI_COLORS[reset]}"
    local c_border="${ANSI_COLORS[$CUR_THEME_BORDER]:-\e[1;34m}"
    local c_tag="${ANSI_COLORS[$CUR_THEME_TAG]:-\e[1;36m}"
    local c_num="\e[1;90m"
    local c_code="\e[0m"

    local lines=('#!/bin/bash' 'echo "Hello, Promptify!"' 'ls -la')
    local f_name="sample.sh"

    case "$idx" in
        0) # Full (Filename + Lines + Grid)
            printf "%b${c_border}── %b${c_tag}%s%b${c_border} ──%b\n" "$spacer" "$reset" "$f_name" "$reset" "$reset"
            printf "%b${c_border}─────────────%b\n" "$spacer" "$reset"
            ;;
        1) # Filename Only
            printf "%b${c_border}── %b${c_tag}%s%b${c_border} ──%b\n" "$spacer" "$reset" "$f_name" "$reset" "$reset"
            ;;
        2|3) : ;;
    esac

    local i
    for i in "${!lines[@]}"; do
        local n=$((i + 1))
        if [[ "$idx" == "1" || "$idx" == "3" ]]; then
            printf "%b%s\n" "$spacer" "${lines[i]}"
        else
            printf "%b${c_num}%2d │%b %s\n" "$spacer" "$n" "$reset" "${lines[i]}"
        fi
    done
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
