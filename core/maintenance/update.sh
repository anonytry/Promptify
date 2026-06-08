#!/bin/bash

check_updates() {
    clear
    promptify_header
    echo -e "\e[1;34m[*] Checking for updates...\e[0m"
    
    # Navigate to script location to check git status
    cd "$INSTALL_DIR" || return 1

    if [[ ! -d ".git" ]]; then
        echo -e "\e[1;31m[!] Not a git repository.\e[0m"
        press_enter
    else
        # 1. Connectivity Check
        if ! git fetch origin main &>/dev/null; then
            echo -e "\e[1;31m[!] Network error: Unable to reach GitHub.\e[0m"
            press_enter
            return 1
        fi

        LOCAL_HASH=$(git rev-parse HEAD)
        REMOTE_HASH=$(git rev-parse origin/main)

        if [[ "$LOCAL_HASH" != "$REMOTE_HASH" ]]; then
            # 2. Local Changes Check (The developer's safety guard)
            if [[ -n "$(git status --porcelain)" ]]; then
                echo -e "\n\e[1;33m[!] WARNING: You have uncommitted local changes.\e[0m"
                echo -e "\e[1;33m[*] Updating will overwrite your WIP code.\e[0m"
                if ! confirm_action "Discard local changes and update anyway?" "n"; then
                    echo -e "\e[1;34m[*] Update aborted to protect your work.\e[0m"
                    press_enter
                    return 0
                fi
            fi

            if confirm_action "Update found! Update now?" "n"; then
                echo -e "\e[1;34m[*] Updating to latest version...\e[0m"
                if git reset --hard origin/main; then
                    echo -e "\n\e[1;32m[✔] Update Successful!\e[0m"
                    
                    # Sync to system dir after update
                    if [[ "$INSTALL_DIR" != "$SYS_DIR" && -d "$SYS_DIR" ]]; then
                        cp -rf "$INSTALL_DIR/." "$SYS_DIR/" 2>/dev/null
                    fi

                    echo -e "\e[1;33m[*] Please run 'Reload & Apply UI' from the main menu to apply any new changes.\e[0m"
                    press_enter
                    exec bash "$INSTALL_DIR/promptify.sh" --local
                else
                    echo -e "\e[1;31m[!] Update failed.\e[0m"
                    press_enter
                fi
            fi
        else
            echo -e "\e[1;32m[✔] Already up to date.\e[0m"
            press_enter
        fi
    fi
}
