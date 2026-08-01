#!/bin/bash

# Resolve active update channel: explicit setting > origin-derived > stable
resolve_channel() {
    local saved
    saved=$(grep "^CHANNEL=" "$HOME/.username" 2>/dev/null | cut -d= -f2- | sed 's/^"//;s/"$//')
    [[ -n "$saved" ]] && { echo "$saved"; return; }

    local origin_url
    origin_url=$(git -C "$INSTALL_DIR" config --get remote.origin.url 2>/dev/null)
    if [[ "$origin_url" == *"anonytry"* ]]; then
        echo "testing"
    else
        echo "stable"
    fi
}

# Persist channel selection
save_channel() {
    local chan="$1"
    set_username_pref CHANNEL "$chan"
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

    local url="$STABLE_URL"
    [[ "$chan" == "testing" ]] && url="$TESTING_URL"

    if confirm_action "Switch to $chan channel?" "n"; then
        echo -e "\e[1;34m[*] \e[32mSwitching to $chan channel...\e[0m"

        save_channel "$chan"
        CUR_CHANNEL="$chan"

        ensure_channel_remote "$chan"

        if [[ -n "$(git -C "$INSTALL_DIR" status --porcelain 2>/dev/null)" ]]; then
            if ! confirm_action "Uncommitted changes exist. Discard them and switch?" "n"; then
                center_print "\e[1;33m[!] Channel switch aborted.\e[0m"
                press_enter
                return
            fi
        fi

        if git -C "$INSTALL_DIR" fetch origin "$CHANNEL_BRANCH" &>/dev/null; then
            git -C "$INSTALL_DIR" reset --hard "origin/$CHANNEL_BRANCH" 2>/dev/null
            center_print "\e[1;32m[✔] Switched to $chan channel.\e[0m"
            center_print "\e[1;33m[*] Run 'Reload & Apply UI' to apply the new version's settings.\e[0m"
            load_prefs
        else
            center_print "\e[1;31m[!] Network error: Unable to reach $url.\e[0m"
        fi
        press_enter
    fi
}
