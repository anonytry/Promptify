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

    setup_ui "$BANNER_NAME" "$CUR_THEME_BORDER" "$CUR_THEME_TAG" "$CUR_FONT" "$USE_BANNER" "$CUR_PROMPT_STYLE"
}

# Notify changes applied (never exec a nested shell)
restart_shell() {
    echo
    echo -e "\e[1;32m[✔] Changes applied!\e[0m"
    echo -e "\e[1;33m[*] Start a new terminal session (or run: source ~/.zshrc) to see them.\e[0m"
    press_enter
}

# Exit script cleanup
exit_script() {
    tput cnorm
    exit 0
}

# Cleanup banner files (keeps other prefs like CAT/CHANNEL in ~/.username)
remove_banner_files() {
    rm -f "$HOME/.draw"
    if [[ -f "$HOME/.username" ]]; then
        sed_i '/^NAME=/d; /^FONT=/d' "$HOME/.username" 2>/dev/null
        if [[ ! -s "$HOME/.username" ]] || ! grep -qE '^[A-Z_]+=' "$HOME/.username"; then
            rm -f "$HOME/.username"
        fi
    fi
}
