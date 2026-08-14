#!/bin/bash

updates_menu() {
    while true; do
        local ch_label="Channel: Stable"
        [[ "$CUR_CHANNEL" == "testing" ]] && ch_label="Channel: Testing"
        MENU_NOTE="\e[2;37mWhat's new? \e[4;36m$(changelog_url)\e[0m"
        UPD_CHOICE=$(radio_menu "Updates & Channel" "updates_panel" "" 0 -1 \
            "Check for Updates" \
            "Version History" \
            "$ch_label" \
            "Back")
        MENU_NOTE=""

        case "$UPD_CHOICE" in
            "CANCELLED") return ;;
            0) check_updates; continue ;;
            1) version_history; continue ;;
            2) manage_channel; continue ;;
            3) return ;;
        esac
    done
}

# Changelog URL for the active channel (repo is derived from the channel).
changelog_url() {
    local repo="$STABLE_URL"
    [[ "$CUR_CHANNEL" == "testing" ]] && repo="$TESTING_URL"
    echo "${repo%.git}/blob/${CHANNEL_BRANCH:-main}/.github/CHANGELOG.md"
}

# Number of saved core snapshots (update history depth).
snapshot_count() {
    ls -1 "$PFY_BACKUP_ARCHIVES"/promptify-v*.tar.gz 2>/dev/null | wc -l
}

# Updates menu header: channel / installed / snapshots + a changelog link note.
updates_panel() {
    local b_clr="\033[1;34m"
    local t_clr="\033[1;36m"
    local r_clr="\033[0m"
    local chan_label="Stable"
    [[ "$CUR_CHANNEL" == "testing" ]] && chan_label="Testing"

    local max_w=0 lw
    local l1="Channel   : $chan_label"
    local l2="Installed : v$VERSION"
    local l3="Snapshots : $(snapshot_count) kept (history)"
    for line in "$l1" "$l2" "$l3"; do
        lw=$(( ${#line} + 2 ))
        [[ $lw -gt $max_w ]] && max_w=$lw
    done

    local box_w
    box_w=$(calc_box_width $((max_w + 6)))
    export BOX_WIDTH=$box_w
    local spacer
    spacer=$(get_spacer "$box_w")

    local title=" Updates & Channel "
    local total_side_len=$((box_w - 2 - ${#title}))
    local side_len=$((total_side_len / 2))
    local side_line
    side_line=$(repeat_char "─" "$side_len")
    local line_top="${spacer}${b_clr}╭${side_line}${t_clr}${title}${b_clr}${side_line}"
    [[ $((total_side_len % 2)) -ne 0 ]] && line_top+="─"
    line_top+="╮${r_clr}"
    printf "%b\n" "$line_top" >&2
    draw_box_line " $l1" "$box_w" "│" "$b_clr" "$spacer" "left" >&2
    draw_box_line " $l2" "$box_w" "│" "$b_clr" "$spacer" "left" >&2
    draw_box_line " $l3" "$box_w" "│" "$b_clr" "$spacer" "left" >&2
    printf "%b\n" "${spacer}${b_clr}╰$(repeat_char "─" $((box_w - 2)))╯${r_clr}" >&2
}

# Update / channel history (append-only, newest last). Fields: ts|from|to|chan_from|chan_to
log_event() {
    local from_ver="$1" to_ver="$2" from_chan="$3" to_chan="$4"
    [[ -d "$PFY_SYS_DIR" ]] || return
    touch "$STATE_FILE" 2>/dev/null || return
    echo "HISTORY|$(date +%s)|$from_ver|$to_ver|$from_chan|$to_chan" >> "$STATE_FILE"

    # Keep all non-history lines + the last 15 history entries.
    if [[ "$(grep -c "^HISTORY|" "$STATE_FILE")" -gt 15 ]]; then
        grep -v "^HISTORY|" "$STATE_FILE" > "$STATE_FILE.tmp" 2>/dev/null
        grep "^HISTORY|" "$STATE_FILE" | tail -n 15 >> "$STATE_FILE.tmp" 2>/dev/null
        mv "$STATE_FILE.tmp" "$STATE_FILE" 2>/dev/null
    fi
}

# Latest history event as "ts|from|to|chan_from|chan_to" (or empty).
read_latest_event() {
    grep "^HISTORY|" "$STATE_FILE" 2>/dev/null | tail -1 | cut -d'|' -f2-
}

# Human text for the latest event: version + channel switch tags, and date.
# "v1.5.0 → v1.5.2 · testing → stable · Aug 14" — same values collapse to one.
last_update_text() {
    local ev
    ev=$(read_latest_event)
    [[ -z "$ev" ]] && { echo "—"; return; }

    local ts from to fc tc
    IFS='|' read -r ts from to fc tc <<< "$ev"

    local vpart="v$from"
    [[ "$from" != "$to" ]] && vpart="v$from → v$to"
    local cpart="$tc"
    [[ -n "$fc" && "$fc" != "$tc" ]] && cpart="$fc → $tc"

    local dpart="—"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        dpart=$(date -r "$ts" "+%b %d %H:%M" 2>/dev/null || echo "—")
    else
        dpart=$(date -d "@$ts" "+%b %d %H:%M" 2>/dev/null || echo "—")
    fi
    echo "$vpart · $cpart · $dpart"
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
    echo -e "    \e[2;37mWhat's new? \e[4;36m$(changelog_url)\e[0m"
    if confirm_action "Update to $target_ver now?" "n"; then
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

    # Archive the running app (core/) before swapping it, so "Version History"
    # can bring it back. Only for persistent installs. Channel is in the name
    # so old snapshots can be told apart from other channels.
    if [[ "$INSTALL_DIR" == "$PFY_CORE" && -d "$PFY_CORE" ]]; then
        mkdir -p "$PFY_BACKUP_ARCHIVES"
        local stamp
        stamp=$(date +%Y%m%d-%H%M%S)
        tar czf "$PFY_BACKUP_ARCHIVES/promptify-v${VERSION}-${stamp}-${CUR_CHANNEL:-stable}.tar.gz" -C "$PFY_SYS_DIR" core 2>/dev/null
        prune_archives
    fi

    echo -e "\e[1;34m[*] Updating to $label...\e[0m"
    if git -C "$INSTALL_DIR" reset --hard "origin/$CHANNEL_BRANCH"; then
        if [[ "$INSTALL_DIR" != "$PFY_CORE" && -d "$PFY_CORE" ]]; then
            sync_to_sys_dir
        fi
        echo -e "\e[1;32m[✔] Update complete!\e[0m"
        local to_ver="$target_ver"
        [[ -z "$to_ver" ]] && to_ver=$(grep -oE 'VERSION="[^"]+"' "$INSTALL_DIR/core/env/version.sh" 2>/dev/null | head -1 | sed 's/VERSION="//;s/"$//')
        log_event "$VERSION" "$to_ver" "$CUR_CHANNEL" "$CUR_CHANNEL"
        post_update_exec
    else
        echo -e "\e[1;31m[!] Update failed.\e[0m"
        press_enter
    fi
}

# Keep only the 5 most recent core archives.
prune_archives() {
    local archives
    mapfile -t archives < <(ls -1t "$PFY_BACKUP_ARCHIVES"/promptify-v*.tar.gz 2>/dev/null)
    local i
    for ((i = 5; i < ${#archives[@]}; i++)); do
        rm -f "${archives[$i]}" 2>/dev/null
    done
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
            local to_ver
            to_ver=$(grep -oE 'VERSION="[^"]+"' "$INSTALL_DIR/core/env/version.sh" 2>/dev/null | head -1 | sed 's/VERSION="//;s/"$//')
            log_event "$VERSION" "$to_ver" "$CUR_CHANNEL" "$CUR_CHANNEL"
            center_print "\e[1;32m[✔] Previous version restored.\e[0m"
            post_update_exec
        else
            center_print "\e[1;31m[!] Could not restore the previous version.\e[0m"
        fi
        press_enter
    fi
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

# Sync a non-persistent clone into the app dir (core/) without leaving stale
# files (keeps deps/, userdata/, runtime/ and backups intact).
sync_to_sys_dir() {
    local src="$INSTALL_DIR/" dst="$PFY_CORE/"
    mkdir -p "$dst"
    if command -v rsync &>/dev/null; then
        rsync -a --delete "$src" "$dst" 2>/dev/null || echo -e "\e[1;33m[*] sync note: final position may differ per variant\e[0m"
    else
        cp -rf "$src" "$dst" 2>/dev/null
        # Portable --delete: drop files in the app dir that no longer exist upstream
        local rel dfile
        while IFS= read -r -d '' dfile; do
            rel="${dfile#"$dst"}"
            if [[ ! -e "${src}${rel}" ]]; then
                rm -rf "$dfile" 2>/dev/null
            fi
        done < <(find "$dst" -type f -print0)
    fi
}
