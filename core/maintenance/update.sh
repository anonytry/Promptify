#!/bin/bash

updates_menu() {
    while true; do
        local ch_label="Channel: Stable"
        [[ "$CUR_CHANNEL" == "testing" ]] && ch_label="Channel: Testing"
        UPD_CHOICE=$(radio_menu "Updates & Channel" "" "" 0 -1 \
            "Check for Updates" \
            "Restore Previous Version" \
            "$ch_label" \
            "Back")

        case "$UPD_CHOICE" in
            "CANCELLED") return ;;
            0) check_updates; return ;;
            1) rollback_update; return ;;
            2) manage_channel; return ;;
            3) return ;;
        esac
    done
}

check_updates() {
    clear
    promptify_header
    echo -e "\e[1;34m[*] Channel: \e[1;33m$CUR_CHANNEL\e[0m \e[1;36m($CHANNEL_BRANCH)\e[0m"
    echo -e "\e[1;34m[*] Checking for updates...\e[0m"

    if [[ ! -d "$INSTALL_DIR/.git" ]]; then
        echo -e "\e[1;31m[!] Not a git repository.\e[0m"
        press_enter
        return
    fi

    # Point origin at the active channel, then fetch
    ensure_channel_remote "$CUR_CHANNEL"
    if ! git -C "$INSTALL_DIR" fetch origin "$CHANNEL_BRANCH" &>/dev/null; then
        echo -e "\e[1;31m[!] Network error: Unable to reach GitHub.\e[0m"
        press_enter
        return 1
    fi

    local local_hash remote_hash
    local_hash=$(git -C "$INSTALL_DIR" rev-parse HEAD)
    remote_hash=$(git -C "$INSTALL_DIR" rev-parse "origin/$CHANNEL_BRANCH")

    if [[ "$local_hash" == "$remote_hash" ]]; then
        echo -e "\e[1;32m[✔] You're on the latest version (v$VERSION).\e[0m"
        press_enter
        return 0
    fi

    local remote_ver cmp
    remote_ver=$(remote_version "origin/$CHANNEL_BRANCH")
    cmp=""
    [[ -n "$remote_ver" ]] && cmp=$(semver_compare "$VERSION" "$remote_ver")

    # Remote is OLDER — never downgrade through an update
    if [[ -n "$remote_ver" && "$cmp" == "gt" ]]; then
        echo -e "\e[1;33m[!] You're on v$VERSION, which is newer than what's available here (v$remote_ver).\e[0m"
        echo -e "\e[1;33m[*] No update needed. Use 'Channel' to switch channels if you want.\e[0m"
        press_enter
        return 0
    fi

    # Same version, but the remote has newer changes (hotfix without a version bump)
    if [[ -n "$remote_ver" && "$cmp" == "eq" ]]; then
        echo -e "\e[1;33m[*] You're on v$VERSION — the same version, but newer changes are available.\e[0m"
        if confirm_action "Sync to the latest changes?" "n"; then
            perform_update "$remote_ver"
        fi
        return 0
    fi

    # Remote is newer (or the version file couldn't be read → fall back to hashes)
    local target_ver="the latest version"
    [[ -n "$remote_ver" ]] && target_ver="v$remote_ver"
    echo -e "\n\e[1;33m[?] Update available: \e[1;32mv$VERSION \e[1;30m→\e[0m \e[1;36m$target_ver\e[0m"
    if confirm_action "View What's New first?" "n"; then
        show_remote_changelog
    fi
    if confirm_action "Update now?" "n"; then
        perform_update "$remote_ver"
    fi
}

perform_update() {
    local target_ver="$1"
    local label="the latest version"
    [[ -n "$target_ver" ]] && label="v$target_ver"

    # Protect tracked work on the program files
    if ! git -C "$INSTALL_DIR" diff --quiet HEAD; then
        echo -e "\n\e[1;33m[!] You have unsaved changes to the program files.\e[0m"
        if ! confirm_action "Replace them and update anyway?" "n"; then
            echo -e "\e[1;34m[*] Update cancelled.\e[0m"
            press_enter
            return 0
        fi
    fi

    # Keep the current version around so it can be restored if needed
    save_last_good "$CUR_CHANNEL"

    echo -e "\e[1;34m[*] Updating to $label...\e[0m"
    if git -C "$INSTALL_DIR" reset --hard "origin/$CHANNEL_BRANCH"; then
        if [[ "$INSTALL_DIR" != "$SYS_DIR" && -d "$SYS_DIR" ]]; then
            sync_to_sys_dir
        fi
        echo -e "\e[1;32m[✔] Update complete!\e[0m"
        post_update_exec
    else
        echo -e "\e[1;31m[!] Update failed.\e[0m"
        press_enter
    fi
}

# Restore the previously saved version (phone-style rollback)
rollback_update() {
    if [[ ! -d "$INSTALL_DIR/.git" ]]; then
        center_print "\e[1;31m[!] Not a git repository.\e[0m"
        press_enter
        return
    fi

    local key="LAST_GOOD_${CUR_CHANNEL^^}"
    local saved_hash
    saved_hash=$(grep "^${key}=" "$STATE_FILE" 2>/dev/null | cut -d= -f2-)
    if [[ -z "$saved_hash" ]]; then
        center_print "\e[1;33m[!] No previous version saved yet.\e[0m"
        press_enter
        return
    fi

    if [[ "$(git -C "$INSTALL_DIR" rev-parse HEAD)" == "$saved_hash" ]]; then
        center_print "\e[1;33m[!] You're already on the previous version.\e[0m"
        press_enter
        return
    fi

    if confirm_action "Restore the previous version? (Your settings will be re-applied)" "n"; then
        if git -C "$INSTALL_DIR" reset --hard "$saved_hash" 2>/dev/null; then
            center_print "\e[1;32m[✔] Previous version restored.\e[0m"
            post_update_exec
        else
            center_print "\e[1;31m[!] Could not restore the previous version.\e[0m"
        fi
        press_enter
    fi
}

# Show the changelog of the newest available version
show_remote_changelog() {
    clear
    promptify_header
    echo -e "\e[1;34m[*] What's New:\e[0m\n"
    git -C "$INSTALL_DIR" show "origin/$CHANNEL_BRANCH:.github/CHANGELOG.md" 2>/dev/null \
        | awk '/^## / { n++ } n == 1 { print } n == 2 { exit }' | head -45
    echo
    press_enter
}

# Reload the new version and auto-apply settings (keeps flags passing through)
post_update_exec() {
    local args=("--local")
    [[ "$CONFIRM_ALL" == "true" ]] && args+=("--yes")
    [[ "$SILENT_MODE" == "true" ]] && args+=("--silent")
    [[ -n "$CUR_CHANNEL" ]] && args+=("--channel" "$CUR_CHANNEL")
    args+=("--post-update")
    exec bash "$INSTALL_DIR/promptify.sh" "${args[@]}"
}

# Sync a non-persistent clone into the system dir without leaving stale files
# (keeps runtime dirs like oh-my-zsh and plugins intact).
sync_to_sys_dir() {
    local src="$INSTALL_DIR/" dst="$SYS_DIR/"
    if command -v rsync &>/dev/null; then
        rsync -a --delete \
            --exclude='oh-my-zsh/' --exclude='plugins/' \
            --exclude='.install-state' --exclude='figlet-backups/' \
            "$src" "$dst" 2>/dev/null
    else
        cp -rf "$src" "$dst" 2>/dev/null
    fi
}
