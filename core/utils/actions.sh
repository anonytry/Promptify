#!/bin/bash

# Navigation back action - REMOVED AS UNUSED

# Instant UI refresh without full reboot
refresh_ui() {
    printf "\033[2J\033[H"
    setup_ui "$BANNER_NAME" "$CUR_THEME_BORDER" "$CUR_THEME_TAG" "$CUR_FONT" "$USE_BANNER"
}

# Restart shell (Left-aligned as requested)
restart_shell() {
    echo
    if confirm_action "Restart Zsh now to apply changes?" "y"; then
        echo -e "\e[1;34m[*] \e[32mRestarting shell...\e[0m"
        sleep 0.5
        exec zsh
    else
        echo -e "\e[1;33m[!] Changes will take effect in new sessions or by running: source ~/.zshrc\e[0m"
        press_enter
    fi
}

# Exit script cleanup
exit_script() {
    tput cnorm
    exit 0
}

# Cleanup banner files
remove_banner_files() {
    rm -f "$HOME/.draw" "$HOME/.username"
}
