#!/bin/bash

manage_banner() {
    while true; do
        BANNER_CHOICE=$(radio_menu "Banner Management" "" "" \
            "Update Banner" \
            "Remove Banner" \
            "Back")

        [[ "$BANNER_CHOICE" == "CANCELLED" || "$BANNER_CHOICE" == 2 ]] && break

        case "$BANNER_CHOICE" in
            0)
                local new_name
                new_name=$(input_prompt "Set Banner Name (max 12)" "$BANNER_NAME" 12 "true")
                [[ "$new_name" == "CANCELLED" || -z "$new_name" ]] && continue

                if confirm_action "Set banner name to '$new_name'?" "y"; then
                    # shellcheck disable=SC2034
                    BANNER_NAME="$new_name"
                    # shellcheck disable=SC2034
                    USE_BANNER="true"
                    calculate_ui_width
                    refresh_ui
                    center_print "\e[1;32m[✔] Applied!\e[0m"
                    restart_shell
                fi
                ;;
            1)
                if confirm_action "Remove banner?" "n"; then
                    # shellcheck disable=SC2034
                    USE_BANNER="false"
                    remove_banner_files
                    refresh_ui
                    center_print "\e[1;32m[✔] Applied!\e[0m"
                    restart_shell
                fi
                ;;
        esac
    done
}
