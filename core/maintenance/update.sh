#!/bin/bash

updates_menu() {
    while true; do
        local ch_label="Channel: Stable"
        [[ "$CUR_CHANNEL" == "testing" ]] && ch_label="Channel: Testing"
        UPD_CHOICE=$(radio_menu "Updates & Channel" "" "" 0 -1 \
            "Check for Updates" \
            "$ch_label" \
            "Back")

        case "$UPD_CHOICE" in
            "CANCELLED") return ;;
            0) check_updates; return ;;
            1) manage_channel ;;
            2) return ;;
        esac
    done
}

check_updates() {
    clear
    promptify_header
    echo -e "\e[1;34m[*] Channel: \e[1;33m$CUR_CHANNEL\e[0m \e[1;36m($CHANNEL_BRANCH)\e[0m"
    echo -e "\e[1;34m[*] Checking for updates...\e[0m"
    
    # Navigate to script location to check git status
    cd "$INSTALL_DIR" || return 1

    if [[ ! -d ".git" ]]; then
        echo -e "\e[1;31m[!] Not a git repository.\e[0m"
        press_enter
    else
        # 0. Point origin at the selected channel before fetching
        ensure_channel_remote "$CUR_CHANNEL"

        # 1. Connectivity Check
        if ! git fetch origin "$CHANNEL_BRANCH" &>/dev/null; then
            echo -e "\e[1;31m[!] Network error: Unable to reach GitHub.\e[0m"
            press_enter
            return 1
        fi

        LOCAL_HASH=$(git rev-parse HEAD)
        REMOTE_HASH=$(git rev-parse "origin/$CHANNEL_BRANCH")

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
                if git reset --hard "origin/$CHANNEL_BRANCH"; then
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
