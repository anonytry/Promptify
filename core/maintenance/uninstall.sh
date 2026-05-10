#!/bin/bash

uninstall_promptify() {
    if ! is_promptify_installed && [[ ! -d "$SYS_DIR" ]]; then
        echo -e "\n \e[1;33m[!] Promptify is not installed or already removed.\e[0m"
        press_enter
        return
    fi

    # 1. Auto-detect components for checkboxes
    local prof_sel="" && is_promptify_installed && prof_sel="|selected"
    local sys_sel="" && [[ -d "$SYS_DIR" ]] && sys_sel="|selected"
    local ui_sel=""
    if [[ "$OS_TYPE" == "termux" ]]; then
        [[ -f "$HOME/.termux/font.ttf.bak" || -f "$HOME/.termux/colors.properties.bak" || -f "$HOME/.termux/termux.properties.bak" ]] && ui_sel="|selected"
    fi
    local asset_sel="" && [[ -f "$HOME/.draw" || -f "$HOME/.username" ]] && asset_sel="|selected"

    # 2. Build Dynamic Menu Options
    local opts=()
    local actions=()

    opts+=("Revert Shell Profile Config$prof_sel")
    actions+=(clean_shell_profile)

    opts+=("Remove Promptify System Directory$sys_sel")
    actions+=(clean_sys_dir)

    # Only show Termux UI option if on Termux
    if [[ "$OS_TYPE" == "termux" ]]; then
        opts+=("Revert Termux UI (Font/Colors)$ui_sel")
        actions+=(clean_ui_settings)
    fi

    opts+=("Remove Home Assets$asset_sel")
    actions+=(clean_assets)

    opts+=("Delete Cloned Repository")
    actions+=(mark_delete_repo)

    # 3. Selection Menu
    local choices
    choices=$(checkbox_menu "Uninstall Management" "${opts[@]}")

    [[ "$choices" == "CANCELLED" || -z "$choices" ]] && return

    if ! confirm_action "Are you sure you want to proceed with uninstallation?" "n"; then
        return
    fi

    echo -e "\n\e[1;34m[*] Starting uninstallation process...\e[0m"

    DELETE_REPO_FLAG=false
    for choice in $choices; do
        action="${actions[$choice]}"
        if [[ "$action" == "mark_delete_repo" ]]; then
            DELETE_REPO_FLAG=true
        else
            $action
        fi
    done

    # 4. Shell Revert Logic
    revert_shell_to_bash

    center_print "\e[1;32m[✔] Cleanup Complete!\e[0m"

    if [[ "$DELETE_REPO_FLAG" == "true" ]]; then
        echo -e "\e[1;33m[!] Warning: This will delete the current folder ($INSTALL_DIR)\e[0m"
        if confirm_action "Finalize deletion?" "y"; then
            cd "$HOME" || exit
            rm -rf "$INSTALL_DIR"
            echo -e "\e[1;31m[*] Repository deleted. Goodbye!\e[0m"
            exit 0
        fi
    fi
    
    press_enter
}

clean_shell_profile() {
    # Clean ~/.zshrc
    if [[ -f "$HOME/.zshrc" ]]; then
        center_print "\e[1;34m[*] \e[0mCleaning ~/.zshrc..."
        sed_i -e '/# --- Promptify Config ---/,/# --- End Promptify Config ---/d' \
              -e '/PROMPTIFY_DIR/d' \
              -e '/build_prompt/d' "$HOME/.zshrc" 2>/dev/null
        
        if [[ -f "$HOME/.zshrc.bak" ]]; then
            center_print "\e[1;34m[*] \e[0mRestoring and cleaning ~/.zshrc.bak..."
            mv "$HOME/.zshrc.bak" "$HOME/.zshrc"
            sed_i '/# --- Promptify Config ---/,/# --- End Promptify Config ---/d' "$HOME/.zshrc" 2>/dev/null
        fi
    fi
    rm -f "$HOME/.zshrc.bak" "$HOME/.zshrc.pre-promptify"

    # Clean ~/.bashrc
    if [[ -f "$HOME/.bashrc" ]]; then
        center_print "\e[1;34m[*] \e[0mCleaning ~/.bashrc..."
        sed_i '/# --- Promptify Config ---/,/# --- End Promptify Config ---/d' "$HOME/.bashrc" 2>/dev/null
    fi
}

clean_sys_dir() {
    # Use a pretty path for display (~/.promptify)
    local display_path="${SYS_DIR/#$HOME/\~}"
    center_print "\e[1;34m[*] \e[0mRemoving system directory ($display_path)..."
    rm -rf "$SYS_DIR"
}

clean_ui_settings() {
    if [[ "$OS_TYPE" == "termux" ]]; then
        center_print "\e[1;34m[*] \e[0mReverting Termux UI settings..."
        local files=("font.ttf" "colors.properties" "termux.properties")
        for f in "${files[@]}"; do
            if [[ -f "$HOME/.termux/${f}.bak" ]]; then
                mv "$HOME/.termux/${f}.bak" "$HOME/.termux/${f}"
            else
                rm -f "$HOME/.termux/${f}"
            fi
        done
        termux-reload-settings 2>/dev/null || true
    fi
}

clean_assets() {
    center_print "\e[1;34m[*] \e[0mCleaning local assets..."
    rm -f "$HOME/.draw" "$HOME/.username" "$HOME/.promptify_font.flf"
}

revert_shell_to_bash() {
    # If we aren't in Zsh or Zsh isn't the default, no need to revert
    [[ "$SHELL" != *"zsh"* ]] && return

    # Try to find a sensible fallback shell
    local fallback_shell="bash"
    [[ -f "/bin/bash" ]] && fallback_shell="/bin/bash"
    [[ -f "/usr/bin/bash" ]] && fallback_shell="/usr/bin/bash"
    
    if confirm_action "Revert default shell to Bash?" "y"; then
        if [[ "$OS_TYPE" == "termux" ]]; then
            chsh -s bash
        else
            local target_user
            target_user=$(whoami)
            $SUDO chsh -s "$fallback_shell" "$target_user" &> /dev/null
        fi
        center_print "\e[1;32m[✔] \033[0mDefault shell reverted."
    fi
}
