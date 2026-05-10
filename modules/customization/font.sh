#!/bin/bash

manage_font() {
    FONT_CHOICE=$(radio_menu "Banner Font Style" "" "font_preview" \
        "Automatic (Width-based)" \
        "Shadow (3D Style)" \
        "Big (Blocky)" \
        "Standard (Simple)" \
        "Back")
    [[ "$FONT_CHOICE" == "CANCELLED" || "$FONT_CHOICE" == 4 ]] && return
    
    local selected_font
    case "$FONT_CHOICE" in
        0) selected_font="auto" ;;
        1) selected_font="shadow" ;;
        2) selected_font="big" ;;
        3) selected_font="std" ;;
    esac
    
    if confirm_action "Use '$selected_font' font style?" "y"; then
        # shellcheck disable=SC2034
        CUR_FONT="$selected_font"
        refresh_ui
        center_print "\e[1;32m[✔] Applied!\e[0m"
        restart_shell
    fi
}
