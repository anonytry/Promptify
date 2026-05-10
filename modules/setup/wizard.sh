#!/bin/bash

guided_setup() {
    # Check if already installed to prevent accidental double-setup
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
        # We can't easily jump out of the function from a trap without exit, 
        # but we can return 1 and let the caller handle it.
        return 1
    }
    trap 'rollback_setup' ERR SIGINT SIGTERM

    [[ -f "$HOME/.zshrc" && ! -f "$zshrc_backup" ]] && cp "$HOME/.zshrc" "$zshrc_backup"

    # Setup terminal and clear for wizard
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

    # Wizard Header with Double-Line Style
    printf "%b\033[1;30mPromptify \033[1;34mv${VERSION}\033[0m\n" "$spacer"
    printf "%b\033[1;34m╔$(repeat_char "═" $((bar_w - 2)))╗\n" "$spacer"
    draw_line "\033[1;37mPROMPTIFY INSTALLATION WIZARD" "$bar_w" "\033[1;34m" "\033[0m" "$spacer"
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

    # Step 2: Banner
    center_print "\033[1;34m[2/3]\033[0m \033[1;33mCreating Your Banner...\033[0m"
    echo
    
    local new_name
    new_name=$(input_prompt "Set Banner Name (max 12)" "Promptify" 12 "true")
    if [[ "$new_name" == "CANCELLED" ]]; then
        if confirm_action "Abort Installation Wizard?" "y"; then
            echo -e " \033[1;31m[!] Setup Cancelled.\033[0m"
            press_enter
            trap - ERR SIGINT SIGTERM
            return 0
        else
            new_name="Promptify"
        fi
    fi

    BANNER_NAME="$new_name"
    # shellcheck disable=SC2034
    USE_BANNER="true"
    calculate_ui_width || true
    # shellcheck disable=SC2034
    read -r CUR_THEME_BORDER CUR_THEME_TAG <<< "$(get_theme_data 0)" || { CUR_THEME_BORDER="red"; CUR_THEME_TAG="blue"; }
    
    echo
    center_print "\033[1;32m[✔] Banner '$BANNER_NAME' Created.\033[0m"
    echo

    # Step 3: Finalizing
    center_print "\033[1;34m[3/3]\033[0m \033[1;33mApplying Settings & Finalizing...\033[0m"
    echo
    refresh_ui || center_print "\033[1;33m[!] UI refresh had minor issues.\033[0m"
    echo
    center_print "\033[1;32m[✔] ALL DONE! Promptify is now persistent.\033[0m"
    center_print "\033[1;33m[*] Location: $SYS_DIR\033[0m"
    
    setup_success=true
    trap - ERR SIGINT SIGTERM
    tput cnorm
    restart_shell
}
