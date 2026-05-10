#!/bin/bash

check_updates() {
    clear
    promptify_header
    echo -e "\e[1;34m[*] Checking for updates...\e[0m"
    if [[ ! -d ".git" ]]; then
        echo -e "\e[1;31m[!] Not a git repository.\e[0m"
        press_enter
    else
        # Sync remote URL if it changed
        local current_remote
        current_remote=$(git remote get-url origin 2>/dev/null)
        if [[ "$current_remote" != "$REPO_URL" ]]; then
            git remote set-url origin "$REPO_URL"
        fi

        git fetch origin main &>/dev/null
        LOCAL_HASH=$(git rev-parse HEAD)
        REMOTE_HASH=$(git rev-parse origin/main)
        if [[ "$LOCAL_HASH" != "$REMOTE_HASH" ]]; then
            if confirm_action "Update found! Update now?" "n"; then
                echo -e "\e[1;34m[*] Updating to latest version...\e[0m"
                if git reset --hard origin/main; then
                    echo -e "\n\e[1;32m[✔] Update Successful!\e[0m"
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
