#!/bin/bash

manage_theme() {
    local active_t="${CUR_THEME_IDX:-0}"
    THEME_CHOICE=$(radio_menu "Prompt Theme Style" "" "theme_preview" "$active_t" "$active_t" \
        "Neon (Cyan/Blue)" \
        "Dracula (Magenta/Cyan)" \
        "Matrix (Green/Green)" \
        "Gold (Yellow/White)" \
        "Classic (Red/Blue)" \
        "Back")

    [[ "$THEME_CHOICE" == "CANCELLED" || "$THEME_CHOICE" == 5 ]] && return
    
    local theme_name
    case "$THEME_CHOICE" in
        0) theme_name="Neon" ;;
        1) theme_name="Dracula" ;;
        2) theme_name="Matrix" ;;
        3) theme_name="Gold" ;;
        4) theme_name="Classic" ;;
    esac

    if confirm_action "Apply '$theme_name' theme?" "y"; then
        # shellcheck disable=SC2034
        read -r CUR_THEME_BORDER CUR_THEME_TAG <<< "$(get_theme_data "$THEME_CHOICE")"
        export CUR_THEME_IDX="$THEME_CHOICE"
        refresh_ui
        center_print "\e[1;32m[✔] Applied!\e[0m"
        restart_shell
    fi
}
