#!/bin/bash

# Bundled figlet fonts installed by Promptify (shared by install + uninstall)
BUNDLED_FONTS=("ASCII-Shadow.flf" "slant.flf" "banner.flf" "smpoison.flf" "graffiti.flf")

# Of those, the figlet package itself ships these — Promptify overwrites them, so
# uninstall may only restore a saved original, never delete them outright.
PACKAGE_OWNED_FONTS=("slant.flf" "banner.flf")

STATE_FILE="$PFY_STATE"

# Read a recorded install fact (prints nothing when unset).
state_fact() {
    local key="$1"
    grep "^${key}=" "$STATE_FILE" 2>/dev/null | head -1 | cut -d= -f2-
}

# Record a one-time install fact (never overwritten once set).
record_install_fact() {
    local key="$1" value="$2"
    [[ -d "$SYS_DIR" ]] || mkdir -p "$SYS_DIR"
    touch "$STATE_FILE"
    if ! grep -q "^${key}=" "$STATE_FILE" 2>/dev/null; then
        echo "${key}=${value}" >> "$STATE_FILE"
    fi
    return 0
}

# Record what Promptify changed so uninstall can reverse exactly that.
# Idempotent: existing keys are never overwritten (e.g. PRE_SHELL must keep the
# value from the very first install, even after re-applies).
record_install_state() {
    [[ -d "$SYS_DIR" ]] || mkdir -p "$SYS_DIR"
    touch "$STATE_FILE"

    # Pre-install default shell: capture once, before any chsh happens.
    if ! grep -q "^PRE_SHELL=" "$STATE_FILE" 2>/dev/null; then
        local pre_shell=""
        if [[ -L "$HOME/.termux/shell" ]]; then
            pre_shell=$(readlink "$HOME/.termux/shell")
        elif [[ -n "${SHELL:-}" ]]; then
            pre_shell="$SHELL"
        fi
        if [[ -n "$pre_shell" ]]; then
            echo "PRE_SHELL=$pre_shell" >> "$STATE_FILE"
        fi
    fi

    # Did the shell profile files exist before us? (0 = we created them)
    if ! grep -q "^HAD_ZSHRC=" "$STATE_FILE" 2>/dev/null; then
        [[ -f "$HOME/.zshrc" ]] && echo "HAD_ZSHRC=1" >> "$STATE_FILE" || echo "HAD_ZSHRC=0" >> "$STATE_FILE"
    fi
    if ! grep -q "^HAD_BASHRC=" "$STATE_FILE" 2>/dev/null; then
        [[ -f "$HOME/.bashrc" ]] && echo "HAD_BASHRC=1" >> "$STATE_FILE" || echo "HAD_BASHRC=0" >> "$STATE_FILE"
    fi

    # Termux UI: which files did we touch (for revert + checkbox auto-select)
    if ! grep -q "^TERMUX_UI=" "$STATE_FILE" 2>/dev/null; then
        if [[ "$OS_TYPE" == "termux" && -d "$HOME/.termux" ]]; then
            echo "TERMUX_UI=1" >> "$STATE_FILE"
        else
            echo "TERMUX_UI=0" >> "$STATE_FILE"
        fi
    fi

    # Desktop (PC): nerd font + terminal configs touched
    if ! grep -q "^DESKTOP_FONT=" "$STATE_FILE" 2>/dev/null; then
        if [[ "$OS_TYPE" != "termux" ]]; then
            echo "DESKTOP_FONT=1" >> "$STATE_FILE"
        else
            echo "DESKTOP_FONT=0" >> "$STATE_FILE"
        fi
    fi
    return 0
}

# Record the sha256 of every file Promptify writes into user-owned locations so
# uninstall can remove exactly what we wrote, even if a later update changed the
# bundled asset. Refresh-on-write: a re-apply overwrites each fingerprint.
record_asset_fingerprints() {
    [[ -d "$SYS_DIR" ]] || mkdir -p "$SYS_DIR"
    touch "$STATE_FILE"
    local files=()
    if [[ "$OS_TYPE" == "termux" ]]; then
        files+=("$HOME/.termux/colors.properties" "$HOME/.termux/font.ttf" "$HOME/.termux/termux.properties")
    else
        files+=("$HOME/.local/share/fonts/JetBrainsMonoNerdFont-Regular.ttf")
    fi
    local f hash
    for f in "${files[@]}"; do
        [[ -f "$f" ]] || continue
        hash=$(sha256sum "$f" 2>/dev/null | awk '{print $1}')
        [[ -z "$hash" ]] && continue
        grep -vF "FP|${f}|" "$STATE_FILE" > "$STATE_FILE.tmp" 2>/dev/null && mv "$STATE_FILE.tmp" "$STATE_FILE"
        echo "FP|${f}|${hash}" >> "$STATE_FILE"
    done
}

# True when the file currently matches a recorded fingerprint (we wrote it).
file_matches_fingerprint() {
    local f="$1"
    [[ -f "$f" ]] || return 1
    local hash
    hash=$(sha256sum "$f" 2>/dev/null | awk '{print $1}')
    [[ -z "$hash" ]] && return 1
    grep -qF "FP|${f}|${hash}" "$STATE_FILE" 2>/dev/null
}

# Remember the current version hash per channel so updates can be rolled back.
# Refresh-on-write (not idempotent): each update overwrites the key.
save_last_good() {    local chan="${1:-${CUR_CHANNEL:-stable}}"
    [[ -d "$SYS_DIR" ]] || mkdir -p "$SYS_DIR"
    touch "$STATE_FILE"
    local key="LAST_GOOD_${chan^^}"
    local hash
    hash=$(git -C "$INSTALL_DIR" rev-parse HEAD 2>/dev/null)
    [[ -n "$hash" ]] || return 0
    grep -v "^${key}=" "$STATE_FILE" > "$STATE_FILE.tmp" 2>/dev/null && mv "$STATE_FILE.tmp" "$STATE_FILE"
    echo "${key}=${hash}" >> "$STATE_FILE"
}

# Load install state into globals. Safe to call on any uninstall path.
# shellcheck disable=SC2034
read_install_state() {
    PRE_SHELL=""
    HAD_ZSHRC=""
    HAD_BASHRC=""
    TERMUX_UI=""
    DESKTOP_FONT=""

    [[ -f "$STATE_FILE" ]] || return 1

    PRE_SHELL=$(grep "^PRE_SHELL=" "$STATE_FILE" | cut -d= -f2- | sed 's/^"//;s/"$//')
    HAD_ZSHRC=$(grep "^HAD_ZSHRC=" "$STATE_FILE" | cut -d= -f2- | sed 's/^"//;s/"$//')
    HAD_BASHRC=$(grep "^HAD_BASHRC=" "$STATE_FILE" | cut -d= -f2- | sed 's/^"//;s/"$//')
    TERMUX_UI=$(grep "^TERMUX_UI=" "$STATE_FILE" | cut -d= -f2- | sed 's/^"//;s/"$//')
    DESKTOP_FONT=$(grep "^DESKTOP_FONT=" "$STATE_FILE" | cut -d= -f2- | sed 's/^"//;s/"$//')
}

# Paths where bundled figlet fonts are copied (termux + desktop)
figlet_font_dirs() {
    if [[ "$OS_TYPE" == "termux" ]]; then
        echo "$PREFIX/share/figlet"
    else
        local dirs="/usr/share/figlet"
        [[ -d "/usr/share/figlet/fonts" ]] && dirs="/usr/share/figlet/fonts"
        echo "$dirs"
    fi
}

# banner.flf and slant.flf are owned by the figlet package itself; copying ours
# OVERWRITES the package's originals. Save those originals (once) so uninstall
# can restore them. Call this BEFORE copying bundled fonts into the figlet dir.
backup_bundled_figlet_fonts() {
    local dir
    dir=$(figlet_font_dirs)
    [[ -d "$dir" ]] || return 0
    local backup_dir="$PFY_BACKUP_FIGLET"
    mkdir -p "$backup_dir"
    local f
    for f in "${BUNDLED_FONTS[@]}"; do
        if [[ -f "$dir/$f" && ! -f "$backup_dir/$f" ]]; then
            cp "$dir/$f" "$backup_dir/$f" 2>/dev/null
        fi
    done
}

# Remove only what Promptify put in the figlet dir (never the package's fonts):
#   - names we have an original backup for        -> restore the backup
#   - package-owned names with no backup          -> leave in place (their original
#     was already overwritten; deleting would break the figlet package)
#   - names with no backup (we created)           -> remove only if it matches our asset
remove_bundled_figlet_fonts() {
    local dir
    dir=$(figlet_font_dirs)
    [[ -d "$dir" ]] || return 0
    local backup_dir="$PFY_BACKUP_FIGLET"
    local sudoprefix=""
    [[ "$OS_TYPE" != "termux" ]] && sudoprefix="$SUDO "
    local f owned=false x
    for f in "${BUNDLED_FONTS[@]}"; do
        if [[ -f "$backup_dir/$f" ]]; then
            $sudoprefix cp "$backup_dir/$f" "$dir/$f" 2>/dev/null || $sudoprefix rm -f "$dir/$f"
            continue
        fi
        owned=false
        for x in "${PACKAGE_OWNED_FONTS[@]}"; do
            [[ "$x" == "$f" ]] && owned=true
        done
        if [[ "$owned" == true ]]; then
            continue
        fi
        if [[ -f "$dir/$f" ]] && cmp -s "$dir/$f" "$INSTALL_DIR/assets/$f" 2>/dev/null; then
            $sudoprefix rm -f "$dir/$f"
        fi
    done
    rm -rf "$backup_dir"
}
