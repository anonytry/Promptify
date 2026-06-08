#!/bin/bash

guided_setup() {
    # Prevent double-setup
    if is_promptify_installed; then
        echo -e "\n \e[1;33m[!] Promptify is already installed.\e[0m"
        if ! confirm_action "Re-run setup wizard? (This will reset current UI settings)" "n"; then
            return 0
        fi
    fi

    # Recovery & Rollback Setup
    local zshrc_backup="$HOME/.zshrc.pre-promptify"
    local setup_success=false
    rollback_setup() {
        if [[ "$setup_success" == "false" ]]; then
            echo -e "\n\033[1;31m[!] Setup failed or interrupted. Rolling back...\033[0m"
            [[ -f "$zshrc_backup" ]] && mv "$zshrc_backup" "$HOME/.zshrc"
        fi
        trap - ERR SIGINT SIGTERM
        tput cnorm
        return 1
    }
    trap 'rollback_setup' ERR SIGINT SIGTERM

    [[ -f "$HOME/.zshrc" && ! -f "$zshrc_backup" ]] && cp "$HOME/.zshrc" "$zshrc_backup"

    # Setup terminal
    tput civis
    printf "\033[2J\033[H"
    
    promptify_header
    
    local term_w
    term_w=$(tput cols)
    local bar_w=52
    [[ -n "$BOX_WIDTH" && $bar_w -lt "$BOX_WIDTH" ]] && bar_w="$BOX_WIDTH"
    [[ $bar_w -gt $((term_w - 2)) ]] && bar_w=$((term_w - 2))
    [[ $bar_w -lt 40 ]] && bar_w=40
    
    local spacer
    spacer=$(get_spacer "$bar_w")

    # Wizard Header
    printf "%b\033[1;30mPromptify \033[1;34mv${VERSION}\033[0m\n" "$spacer"
    printf "%b\033[1;34m╔$(repeat_char "═" $((bar_w - 2)))╗\n" "$spacer"
    draw_box_line "\033[1;37mPROMPTIFY INSTALLATION WIZARD" "$bar_w" "║" "\033[1;34m" "$spacer" "center"
    printf "%b\033[1;34m╚$(repeat_char "═" $((bar_w - 2)))╝\033[0m\n\n" "$spacer"

    # Step 1: Environment
    center_print "\033[1;34m[1/3]\033[0m \033[1;33mSetting up Environment...\033[0m"
    echo
    install_dependencies || { center_print "\033[1;31m[!] Dependencies failed.\033[0m"; press_enter; return 1; }
    install_omz || { center_print "\033[1;31m[!] Oh-My-Zsh failed.\033[0m"; press_enter; return 1; }
    install_plugins || { center_print "\033[1;31m[!] Plugins failed.\033[0m"; press_enter; return 1; }
    sync_assets
    echo
    center_print "\033[1;32m[✔] Environment Ready.\033[0m"
    echo

    # Step 2: UI Preferences
    center_print "\033[1;34m[2/3]\033[0m \033[1;33mCustomizing Your Experience...\033[0m"
    echo
    
    if confirm_action "Enable ASCII Banner on startup?" "y"; then
        USE_BANNER="true"
        local def_name
        def_name=$(whoami 2>/dev/null || echo "User")
        
        local new_name
        new_name=$(input_prompt "Enter Banner Name (max 12)" "$def_name" 12 "false")
        
        if [[ "$new_name" == "CANCELLED" ]]; then
             BANNER_NAME="$def_name"
        else
             BANNER_NAME="$new_name"
        fi
        center_print "\033[1;32m[✔] Banner '$BANNER_NAME' Enabled.\033[0m"
    else
        USE_BANNER="false"
        BANNER_NAME="Promptify"
        center_print "\033[1;32m[✔] Banner Disabled.\033[0m"
    fi
    echo

    # Step 3: Finalizing
    center_print "\033[1;34m[3/3]\033[0m \033[1;33mApplying Settings & Finalizing...\033[0m"
    echo
    
    # Persistent Repo Migration
    if [[ "$INSTALL_DIR" != "$SYS_DIR" ]]; then
        center_print "\e[1;34m[*] \e[0mInstalling Promptify to system..."
        mkdir -p "$SYS_DIR"
        # Copy repository
        cp -rf "$INSTALL_DIR/." "$SYS_DIR/" 2>/dev/null
        # Update session path
        INSTALL_DIR="$SYS_DIR"
    fi

    refresh_ui || center_print "\033[1;33m[!] UI refresh had minor issues.\033[0m"
    echo
    center_print "\033[1;32m[✔] ALL DONE! Promptify is now persistent.\033[0m"
    center_print "\033[1;33m[*] Location: $SYS_DIR\033[0m"
    
    setup_success=true
    trap - ERR SIGINT SIGTERM
    tput cnorm
    restart_shell
}
