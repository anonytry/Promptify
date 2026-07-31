#!/bin/bash

manage_customization() {
    while true; do
        local cat_opt="Cat Display Style"
        if ! is_installed bat && ! is_installed batcat; then
            cat_opt="Cat Display Style (bat not installed)|disabled"
        fi

        CUST_CHOICE=$(radio_menu "Customization Menu" "" "" 0 -1 \
            "Banner Management" \
            "Banner Font Style" \
            "Prompt Theme Style" \
            "$cat_opt" \
            "Back")

        [[ "$CUST_CHOICE" == "CANCELLED" || "$CUST_CHOICE" == 4 ]] && break

        case "$CUST_CHOICE" in
            0) manage_banner ;;
            1) manage_font ;;
            2) manage_theme ;;
            3) manage_cat ;;
        esac
    done
}
