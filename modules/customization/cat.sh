#!/bin/bash

manage_cat() {
    if ! is_installed bat && ! is_installed batcat; then
        center_print "\e[1;31m[!] bat is not installed.\e[0m"
        center_print "\e[1;33m[*] Install it from Dependencies > Power Tools.\e[0m"
        press_enter
        return
    fi

    local cur_idx=0
    case "$CUR_CAT_STYLE" in
        "full") cur_idx=0 ;;
        "header-filename") cur_idx=1 ;;
        "numbers") cur_idx=2 ;;
        "plain") cur_idx=3 ;;
    esac

    CAT_CHOICE=$(radio_menu "Cat Display Style" "" "cat_preview" "$cur_idx" "$cur_idx" \
        "Full" \
        "Filename Only" \
        "Numbers Only" \
        "Plain" \
        "Back")

    [[ "$CAT_CHOICE" == "CANCELLED" || "$CAT_CHOICE" == 4 ]] && return

    local style
    case "$CAT_CHOICE" in
        0) style="full" ;;
        1) style="header-filename" ;;
        2) style="numbers" ;;
        3) style="plain" ;;
    esac

    if confirm_action "Apply '$style' cat style?" "y"; then
        # shellcheck disable=SC2034
        CUR_CAT_STYLE="$style"

        set_pref CAT "$style"

        load_prefs
        refresh_ui
        center_print "\e[1;32m[✔] Applied!\e[0m"
        restart_shell
    fi
}
