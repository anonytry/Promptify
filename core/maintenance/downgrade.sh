#!/bin/bash

# Version History / downgrade: list archived core/ tarballs (created by
# update.sh before every update) and restore any previous version, re-applying
# settings. Everything else — deps, userdata, snapshot — is left untouched.

list_archives() {
    mkdir -p "$PFY_BACKUP_ARCHIVES" 2>/dev/null
    ls -1t "$PFY_BACKUP_ARCHIVES"/promptify-v*.tar.gz 2>/dev/null
}

# Channel of an archive: from the filename suffix when present, otherwise
# probed from the archived core/.git/config remote URL (archives predating the
# suffix were created before the channel was tracked in the name).
archive_channel() {
    local archive="$1" base
    base=$(basename "$archive" .tar.gz)
    if [[ "$base" =~ -(stable|testing)$ ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    local url norm
    url=$(tar xzOf "$archive" core/.git/config 2>/dev/null | sed -n '/\[remote "origin"\]/,/^\[/s/^[[:space:]]*url = //p' | head -1)
    norm=$(echo "$url" | tr 'A-Z' 'a-z')
    case "$norm" in
        *anonytry*|*anonytrip*) echo "testing" ;;
        *) echo "stable" ;;
    esac
}

# Rename archives created before the channel suffix so every name reads
# promptify-v<ver>-<stamp>-<chan>.tar.gz (detected channel is preserved).
backfill_archive_channels() {
    local a base chan newname
    for a in "$PFY_BACKUP_ARCHIVES"/promptify-v*.tar.gz; do
        [[ -f "$a" ]] || continue
        base=$(basename "$a" .tar.gz)
        [[ "$base" =~ -(stable|testing)$ ]] && continue
        chan=$(archive_channel "$a")
        newname="$(dirname "$a")/promptify-v${base#promptify-v}-${chan}.tar.gz"
        [[ "$newname" != "$a" ]] && mv "$a" "$newname" 2>/dev/null
    done
}

# "Aug 13 22:59" from an archive stamp like 20260813-225958
archive_date_text() {
    local stamp="$1"
    local ymd="${stamp%%-*}" tm="${stamp#*-}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        date -j -f "%Y%m%d-%H%M%S" "$stamp" "+%b %d %H:%M" 2>/dev/null || echo "$ymd"
    else
        date -d "${ymd:0:4}-${ymd:4:2}-${ymd:6:2} ${tm:0:2}:${tm:2:2}:${tm:4:2}" "+%b %d %H:%M" 2>/dev/null || echo "$ymd"
    fi
}

# Version History header box: installed version, latest update (version +
# channel tags), snapshot count.
version_history_panel() {
    local b_clr="\033[1;34m"
    local t_clr="\033[1;36m"
    local r_clr="\033[0m"
    local chan_label="Stable"
    [[ "$CUR_CHANNEL" == "testing" ]] && chan_label="Testing"

    local max_w=0 lw
    local l1="Channel   : $chan_label"
    local l2="Installed : v$VERSION"
    local l3="Updated   : $(last_update_text)"
    local l4="Snapshots : $(snapshot_count) kept"
    for line in "$l1" "$l2" "$l3" "$l4"; do
        lw=$(( ${#line} + 2 ))
        [[ $lw -gt $max_w ]] && max_w=$lw
    done

    local box_w
    box_w=$(calc_box_width $((max_w + 6)))
    export BOX_WIDTH=$box_w
    local spacer
    spacer=$(get_spacer "$box_w")

    local title=" Version History "
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
    draw_box_line " $l4" "$box_w" "│" "$b_clr" "$spacer" "left" >&2
    printf "%b\n" "${spacer}${b_clr}╰$(repeat_char "─" $((box_w - 2)))╯${r_clr}" >&2
}

version_history() {
    backfill_archive_channels

    local archives=()
    mapfile -t archives < <(list_archives)

    # Nothing archived yet: fall back to the git-saved previous version.
    if [[ ${#archives[@]} -eq 0 ]]; then
        rollback_update
        return
    fi

    # Build restore labels: "v1.5.0 (testing) · Aug 13 22:59" (newest first).
    local opts=() labels=() ver stamp chan date_text
    local a base rest
    for a in "${archives[@]}"; do
        base=$(basename "$a" .tar.gz)   # promptify-v1.5.0-20260813-225958-testing
        rest="${base#promptify-v}"      # 1.5.0-20260813-225958-testing
        ver="${rest%%-*}"               # 1.5.0
        rest="${rest#*-}"               # 20260813-225958-testing
        chan=$(archive_channel "$a")
        stamp="$rest"
        [[ -n "$chan" ]] && stamp="${rest%-$chan}"
        date_text=$(archive_date_text "$stamp")
        labels+=("v$ver ($chan) · $date_text")
        opts+=("v$ver ($chan) · $date_text")
    done
    opts+=("Back")

    local choice
    choice=$(radio_menu "Version History" "version_history_panel" "" 0 -1 "${opts[@]}")
    [[ "$choice" == "CANCELLED" || "$choice" -ge ${#archives[@]} ]] && return

    local archive="${archives[$choice]}"
    local label="${labels[$choice]}"
    local snap_chan
    snap_chan=$(archive_channel "$archive")

    if [[ -n "$snap_chan" && "$snap_chan" != "$CUR_CHANNEL" ]]; then
        echo
        center_print "\e[1;33m[!] This snapshot is from the \e[1;36m$snap_chan\e[0m channel (you're on \e[1;36m$CUR_CHANNEL\e[0m)."
        center_print "\e[1;33m[*] Only the code is reverted — your channel preference is kept.\e[0m"
    fi

    if confirm_action "Restore $label? Your settings will be re-applied." "n"; then
        # Protect tracked work on the program files
        if ! git -C "$INSTALL_DIR" diff --quiet HEAD 2>/dev/null; then
            if ! confirm_action "Unsaved changes exist. Replace them and restore?" "n"; then
                center_print "\e[1;33m[!] Restore cancelled.\e[0m"
                press_enter
                return
            fi
        fi

        center_print "\e[1;34m[*] \e[0mRestoring $label..."
        # Extract into a temp dir first, then swap — a corrupt archive can never
        # destroy the running app.
        local tmpdir
        tmpdir=$(mktemp -d "$PFY_SYS_DIR/.restore.XXXXXX" 2>/dev/null) || tmpdir="$PFY_SYS_DIR/.restore"
        if ! tar xzf "$archive" -C "$tmpdir" 2>/dev/null || [[ ! -d "$tmpdir/core" ]]; then
            rm -rf "$tmpdir"
            center_print "\e[1;31m[!] Archive is corrupt or unreadable.\e[0m"
            press_enter
            return
        fi
        rm -rf "$PFY_CORE"
        if ! mv "$tmpdir/core" "$PFY_CORE" 2>/dev/null; then
            mkdir -p "$PFY_CORE"
            cp -a "$tmpdir/core/." "$PFY_CORE/" 2>/dev/null
            rm -rf "$tmpdir/core"
        fi
        rm -rf "$tmpdir"
        record_install_fact LAYOUT 2
        ensure_channel_remote "$CUR_CHANNEL"
        log_event "$VERSION" "$ver" "$CUR_CHANNEL" "$snap_chan"
        center_print "\e[1;32m[✔] $label restored.\e[0m"
        post_update_exec
    fi
    press_enter
}
