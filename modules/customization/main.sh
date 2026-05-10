#!/bin/bash

manage_customization() {
    while true; do
        CUST_CHOICE=$(radio_menu "Customization Menu" "" "" \
            "Banner Management" \
            "Banner Font Style" \
            "Prompt Theme Style" \
            "Back")

        [[ "$CUST_CHOICE" == "CANCELLED" || "$CUST_CHOICE" == 3 ]] && break

        case "$CUST_CHOICE" in
            0) manage_banner ;;
            1) manage_font ;;
            2) manage_theme ;;
        esac
    done
}
