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

# Start a fresh interactive Zsh so applied changes are visible immediately,
# without exiting and reopening the terminal. The fresh shell starts in the
# directory Promptify was launched from, never in the clone/system dir.
reload_shell() {
    cd -- "${ORIGINAL_DIR:-$HOME}" 2>/dev/null
    exec zsh
}

is_interactive() {
    [[ -t 0 ]]
}

# Ask whether to reload the shell after changes are applied. On "no" — or when
# not attached to a real terminal — just show the notice instead.
restart_shell() {
    echo
    if is_interactive && command -v zsh &>/dev/null; then
        if confirm_action "Restart Zsh now to apply changes?" "y"; then
            echo -e "\e[1;34m[*] \e[32mRestarting shell...\e[0m"
            sleep 0.5
            reload_shell
        fi
    fi
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
