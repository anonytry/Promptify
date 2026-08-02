#!/bin/bash

manage_prompt() {
    local cur_idx=0
    case "$CUR_PROMPT_STYLE" in
        "fish") cur_idx=1 ;;
        "minimal") cur_idx=2 ;;
    esac

    PROMPT_CHOICE=$(radio_menu "Prompt Style" "" "prompt_preview" "$cur_idx" "$cur_idx" \
        "Parrot" \
        "Fish" \
        "Minimal" \
        "Back")

    [[ "$PROMPT_CHOICE" == "CANCELLED" || "$PROMPT_CHOICE" == 3 ]] && return

    local style
    case "$PROMPT_CHOICE" in
        0) style="parrot" ;;
        1) style="fish" ;;
        2) style="minimal" ;;
    esac

    if confirm_action "Apply '$style' prompt style?" "y"; then
        # shellcheck disable=SC2034
        CUR_PROMPT_STYLE="$style"

        set_username_pref STYLE "$style"

        load_prefs
        refresh_ui
        center_print "\e[1;32m[✔] Applied!\e[0m"
        restart_shell
    fi
}
