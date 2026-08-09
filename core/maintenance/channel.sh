#!/bin/bash

# Resolve active update channel: explicit setting > origin-derived > stable
resolve_channel() {
    local prefs_file="$PFY_PREFS"
    [[ -f "$prefs_file" ]] || prefs_file="$HOME/.username"
    local saved
    saved=$(get_pref CHANNEL "$prefs_file" "")
    [[ -n "$saved" ]] && { echo "$saved"; return; }

    local origin_url
    origin_url=$(git -C "$INSTALL_DIR" config --get remote.origin.url 2>/dev/null)
    [[ "$origin_url" == "$TESTING_URL" ]] && echo "testing" || echo "stable"
}

# Persist channel selection
save_channel() {
    local chan="$1"
    set_pref CHANNEL "$chan"
}

# Point origin remote at the active channel's repo/branch
ensure_channel_remote() {
    local chan="${1:-$CUR_CHANNEL}"
    [[ -d "$INSTALL_DIR/.git" ]] || return 1

    local target_url="$STABLE_URL"
    [[ "$chan" == "testing" ]] && target_url="$TESTING_URL"

    local current_url
    current_url=$(git -C "$INSTALL_DIR" config --get remote.origin.url 2>/dev/null)
    if [[ "$current_url" != "$target_url" ]]; then
        git -C "$INSTALL_DIR" remote set-url origin "$target_url" 2>/dev/null || return 1
    fi
}

# Repo URL for a channel (defaults to active channel)
channel_url() {
    [[ "${1:-$CUR_CHANNEL}" == "testing" ]] && echo "$TESTING_URL" || echo "$STABLE_URL"
}

# Fetch both channels into local refs so their versions can be shown together
fetch_channel_versions() {
    git -C "$INSTALL_DIR" fetch --quiet "$STABLE_URL" "$CHANNEL_BRANCH:refs/channels/stable" 2>/dev/null
    git -C "$INSTALL_DIR" fetch --quiet "$TESTING_URL" "$CHANNEL_BRANCH:refs/channels/testing" 2>/dev/null
}

# Channel switch UI
manage_channel() {
    if [[ ! -d "$INSTALL_DIR/.git" ]]; then
        center_print "\e[1;31m[!] Not a git repository.\e[0m"
        press_enter
        return
    fi

    local cur_idx=0
    [[ "$CUR_CHANNEL" == "testing" ]] && cur_idx=1

    CH_CHOICE=$(radio_menu "Update Channel" "" "" "$cur_idx" "$cur_idx" \
        "Stable" \
        "Testing" \
        "Back")

    [[ "$CH_CHOICE" == "CANCELLED" || "$CH_CHOICE" == 2 ]] && return

    local chan="stable"
    [[ "$CH_CHOICE" == "1" ]] && chan="testing"

    if [[ "$chan" == "$CUR_CHANNEL" ]]; then
        center_print "\e[1;33m[!] You're already on the $chan channel.\e[0m"
        press_enter
        return
    fi

    # Show what version each channel is on before switching
    local stable_ver testing_ver target_ver
    stable_ver="?"
    testing_ver="?"
    if fetch_channel_versions; then
        stable_ver=$(remote_version "refs/channels/stable")
        testing_ver=$(remote_version "refs/channels/testing")
    fi
    [[ -z "$stable_ver" ]] && stable_ver="?"
    [[ -z "$testing_ver" ]] && testing_ver="?"

    clear
    promptify_header
    echo -e "\n \e[1;34m[*] Channels:\e[0m"
    echo -e "   \e[1;36mStable  \e[1;30m→\e[0m v$stable_ver"
    echo -e "   \e[1;36mTesting \e[1;30m→\e[0m v$testing_ver"
    echo

    target_ver="$stable_ver"
    [[ "$chan" == "testing" ]] && target_ver="$testing_ver"

    if [[ "$target_ver" != "?" && "$(semver_compare "$VERSION" "$target_ver")" == "gt" ]]; then
        echo -e " \e[1;33m[!] Switching to $chan (v$target_ver) is a \e[1;31mdowngrade\e[0m from your current v$VERSION."
        echo
    fi

    if confirm_action "Switch to the $chan channel?" "n"; then
        echo -e "\e[1;34m[*] \e[32mSwitching to $chan channel...\e[0m"

        # Protect tracked work on the program files
        if ! git -C "$INSTALL_DIR" diff --quiet HEAD; then
            if ! confirm_action "Unsaved changes exist. Replace them and switch?" "n"; then
                center_print "\e[1;33m[!] Channel switch cancelled.\e[0m"
                press_enter
                return
            fi
        fi

        # Remember the version we leave behind on this channel
        save_last_good "$CUR_CHANNEL"

        save_channel "$chan"
        CUR_CHANNEL="$chan"
        ensure_channel_remote "$chan"

        if git -C "$INSTALL_DIR" reset --hard "refs/channels/$chan" 2>/dev/null; then
            if [[ "$INSTALL_DIR" != "$PFY_CORE" && -d "$PFY_CORE" ]]; then
                sync_to_sys_dir
            fi
            center_print "\e[1;32m[✔] Switched to $chan channel.\e[0m"
            load_prefs
            post_update_exec
        else
            center_print "\e[1;31m[!] Network error: Unable to reach the channel.\e[0m"
        fi
        press_enter
    fi
}
