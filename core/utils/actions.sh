#!/bin/bash

# Instant UI refresh without full reboot
refresh_ui() {
    printf "\033[2J\033[H"
    
    # Auto-sync core files if running from a local repo to the system dir
    if [[ "$INSTALL_DIR" != "$SYS_DIR" && -d "$SYS_DIR" ]]; then
        cp -rf "$INSTALL_DIR/core" "$SYS_DIR/" 2>/dev/null
        cp -rf "$INSTALL_DIR/modules" "$SYS_DIR/" 2>/dev/null
        cp -rf "$INSTALL_DIR/assets" "$SYS_DIR/" 2>/dev/null
        cp -f "$INSTALL_DIR/promptify.sh" "$SYS_DIR/" 2>/dev/null
    fi

    setup_ui "$BANNER_NAME" "$CUR_THEME_BORDER" "$CUR_THEME_TAG" "$CUR_FONT" "$USE_BANNER"
}

# Restart shell
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
