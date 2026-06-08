#!/bin/bash

manage_font() {
    local cur_f_idx
    cur_f_idx=$(get_font_idx "$CUR_FONT")

    FONT_CHOICE=$(radio_menu "Banner Font Style" "" "font_preview" "$cur_f_idx" "$cur_f_idx" \
        "$(get_font_label 0)" \
        "$(get_font_label 1)" \
        "$(get_font_label 2)" \
        "Back")
    [[ "$FONT_CHOICE" == "CANCELLED" || "$FONT_CHOICE" == 3 ]] && return

    local selected_font
    selected_font=$(get_font_name "$FONT_CHOICE")

    
    if confirm_action "Use '$selected_font' font style?" "y"; then
        # shellcheck disable=SC2034
        CUR_FONT="$selected_font"
        
        echo "NAME=\"$BANNER_NAME\"" > "$HOME/.username"
        echo "FONT=\"$CUR_FONT\"" >> "$HOME/.username"
        
        load_prefs
        calculate_ui_width
        refresh_ui
        center_print "\e[1;32m[✔] Applied!\e[0m"
        restart_shell
    fi
}
