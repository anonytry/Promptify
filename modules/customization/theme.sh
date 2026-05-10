#!/bin/bash

manage_theme() {
    THEME_CHOICE=$(radio_menu "Prompt Theme Style" "" "theme_preview" \
        "Neon (Cyan/Blue)" \
        "Dracula (Magenta/Cyan)" \
        "Matrix (Green/Green)" \
        "Gold (Yellow/White)" \
        "Classic (Red/Blue)" \
        "Back")
    # Set default cursor logic for radio_menu would need to be in radio_menu itself
    # For now, let's keep it simple as the user didn't ask for default selection
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
