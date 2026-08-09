#!/bin/bash

# Downgrade: restore an older core/ version from backup/archives (created by
# update.sh before every update). Everything else — deps, userdata, snapshot —
# is left untouched.

list_archives() {
    mkdir -p "$PFY_BACKUP_ARCHIVES" 2>/dev/null
    ls -1t "$PFY_BACKUP_ARCHIVES"/promptify-v*.tar.gz 2>/dev/null
}

downgrade_menu() {
    local archives=()
    mapfile -t archives < <(list_archives)
    if [[ ${#archives[@]} -eq 0 ]]; then
        center_print "\e[1;33m[!] No archived versions available yet. Run an update first.\e[0m"
        press_enter
        return
    fi

    local opts=() base ver
    for a in "${archives[@]}"; do
        base=$(basename "$a" .tar.gz)
        ver="${base#promptify-v}"
        opts+=("$ver")
    done
    opts+=("Back")

    local choice
    choice=$(radio_menu "Restore Older Version" "" "" 0 -1 "${opts[@]}")
    [[ "$choice" == "CANCELLED" || "$choice" -ge $(( ${#archives[@]} )) ]] && return

    local archive="${archives[$choice]}"
    if confirm_action "Restore version '${opts[$choice]}'? Your settings will be re-applied." "n"; then
        # Protect tracked work on the program files
        if ! git -C "$INSTALL_DIR" diff --quiet HEAD 2>/dev/null; then
            if ! confirm_action "Unsaved changes exist. Replace them and downgrade?" "n"; then
                center_print "\e[1;33m[!] Downgrade cancelled.\e[0m"
                press_enter
                return
            fi
        fi

        center_print "\e[1;34m[*] \e[0mRestoring ${opts[$choice]}..."
        rm -rf "$PFY_CORE"
        mkdir -p "$PFY_CORE"
        if ! tar xzf "$archive" -C "$PFY_SYS_DIR" 2>/dev/null; then
            center_print "\e[1;31m[!] Archive is corrupt or unreadable.\e[0m"
            press_enter
            return
        fi
        record_install_fact LAYOUT 2
        center_print "\e[1;32m[✔] ${opts[$choice]} restored.\e[0m"
        post_update_exec
    fi
    press_enter
}
