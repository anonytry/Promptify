#!/bin/bash

# Migration from the legacy (≤1.4.3) inline-block layout to the new APK-style
# ~/.promptify layout. Runs once, automatically, when an old install is found.
#
# What it does:
#   1. Recovers the TRUE pre-Promptify profiles (strips the old inline blocks)
#      and snapshots them so uninstall restores them exactly.
#   2. Converts ~/.username prefs -> userdata/prefs.conf.
#   3. Moves oh-my-zsh/plugins -> deps/, figlet backups -> backup/system/figlet.
#   4. Restructures the code into core/ (app dir).
#   5. Rewrites ~/.zshrc / ~/.bashrc to single managed source lines and
#      regenerates the runtime config.

is_legacy_layout() {
    [[ -f "$PFY_MANIFEST" ]] && return 1
    if [[ -f "$HOME/.zshrc" ]] && grep -q "# --- Promptify Config ---" "$HOME/.zshrc" 2>/dev/null; then
        return 0
    fi
    if [[ -d "$SYS_DIR/oh-my-zsh" || -d "$SYS_DIR/plugins" || -f "$SYS_DIR/promptify.sh" ]]; then
        return 0
    fi
    return 1
}

# Strip the legacy inline Promptify block from a profile copy (never the real
# file — callers pass a scratch copy).
strip_inline_block() {
    local file="$1"
    sed_i -e "/# --- Promptify Config ---/,/# --- End Promptify Config ---/d" \
          -e '/^export PROMPTIFY_DIR=/d' \
          -e '/^PROMPTIFY_DIR=/d' \
          -e '/^export ZSH=/d' \
          -e '/build_prompt/d' \
          -e '/precmd_functions/d' \
          -e '/alias Promptify=/d' \
          -e '/alias pty=/d' \
          -e '/^ZSH_THEME=/d' "$file" 2>/dev/null
}

# Snapshot a recovered original profile as a P| entry (skipped when empty —
# the caller then marks the profile as created instead).
snapshot_recovered_profile() {
    local path="$1" scratch="$2"
    [[ -s "$scratch" ]] || return 0
    local idx name
    idx=$(find "$PFY_BACKUP_FILES" -maxdepth 1 -type f 2>/dev/null | wc -l)
    name="f${idx}"
    while [[ -e "$PFY_BACKUP_FILES/$name" ]]; do
        idx=$((idx + 1)); name="f${idx}"
    done
    cp -p "$scratch" "$PFY_BACKUP_FILES/$name" 2>/dev/null || return 1
    local hash
    hash=$(sha256_of "$scratch")
    echo "P|${path}|${name}|${hash}" >> "$PFY_MANIFEST"
}

migrate_legacy() {
    [[ -f "$PFY_MANIFEST" ]] && return 0
    is_legacy_layout || return 0

    echo -e "\n\e[1;34m[*]\e[0m Legacy Promptify install detected — migrating to the new layout..."
    init_manifest

    # --- 1. Recover + snapshot the true pre-Promptify profiles ---
    local raw stripped
    raw=$(mktemp); stripped=$(mktemp)

    if [[ -f "$HOME/.zshrc" ]]; then
        cp "$HOME/.zshrc" "$raw"
        # Remember legacy theme colors before they're stripped away.
        local old_b old_t
        old_b=$(grep "^P_CLR_BORDER=" "$raw" | head -1 | cut -d= -f2- | tr -d '"')
        old_t=$(grep "^P_CLR_TAG=" "$raw" | head -1 | cut -d= -f2- | tr -d '"')
        cp "$raw" "$stripped"; strip_inline_block "$stripped"
        snapshot_recovered_profile "$HOME/.zshrc" "$stripped"
        # Facts come from the USER's original, not the stripped-away block.
        # Broad match: distro configs (e.g. cachyos-config.zsh) load omz and
        # p10k without naming them in ~/.zshrc.
        if grep -q 'oh-my-zsh\|ohmyzsh\|cachyos-zsh-config' "$stripped" 2>/dev/null; then
            record_install_fact ORIG_OMZ 1
        else
            record_install_fact ORIG_OMZ 0
        fi
        if grep -qi 'powerlevel9k\|powerlevel10k\|p10k\|cachyos-zsh-config' "$stripped" 2>/dev/null \
           || [[ -f "$HOME/.p10k.zsh" ]]; then
            record_install_fact ORIG_P10K 1
        else
            record_install_fact ORIG_P10K 0
        fi
        [[ -n "$old_b" ]] && set_pref THEME_BORDER "$old_b" 2>/dev/null
        [[ -n "$old_t" ]] && set_pref THEME_TAG "$old_t" 2>/dev/null
    else
        record_install_fact ORIG_OMZ 0
        record_install_fact ORIG_P10K 0
    fi

    if [[ -f "$HOME/.bashrc" ]]; then
        cp "$HOME/.bashrc" "$raw"
        cp "$raw" "$stripped"; strip_inline_block "$stripped"
        snapshot_recovered_profile "$HOME/.bashrc" "$stripped"
    fi

    rm -f "$raw" "$stripped"

    # --- 2. Prefs: ~/.username -> userdata/prefs.conf ---
    if [[ -f "$HOME/.username" && ! -f "$PFY_PREFS" ]]; then
        mkdir -p "$PFY_USERDATA"
        cp -p "$HOME/.username" "$PFY_PREFS"
        chmod 600 "$PFY_PREFS" 2>/dev/null
    fi

    # --- 3. Dependencies -> deps/ ---
    mkdir -p "$PFY_DEPS"
    [[ -d "$SYS_DIR/oh-my-zsh" && ! -d "$PFY_DEPS_OMZ" ]] && mv "$SYS_DIR/oh-my-zsh" "$PFY_DEPS_OMZ" 2>/dev/null
    [[ -d "$SYS_DIR/plugins" && ! -d "$PFY_DEPS_PLUGINS" ]] && mv "$SYS_DIR/plugins" "$PFY_DEPS_PLUGINS" 2>/dev/null
    [[ -d "$SYS_DIR/figlet-backups" && ! -d "$PFY_BACKUP_FIGLET" ]] && mv "$SYS_DIR/figlet-backups" "$PFY_BACKUP_FIGLET" 2>/dev/null

    # --- 4. Code -> core/ (app dir) ---
    if [[ ! -f "$PFY_CORE/promptify.sh" ]]; then
        mkdir -p "$PFY_CORE"
        local item
        for item in promptify.sh modules assets .git; do
            [[ -e "$SYS_DIR/$item" ]] && mv "$SYS_DIR/$item" "$PFY_CORE/$item" 2>/dev/null
        done
        # The old module dir becomes core/core
        if [[ -d "$SYS_DIR/core" ]]; then
            mv "$SYS_DIR/core" "$PFY_CORE/core" 2>/dev/null
        fi
    fi

    # --- 5. State + runtime + managed profiles ---
    record_install_state
    record_install_fact LAYOUT 2
    generate_runtime
    write_managed_profiles
    generate_self_uninstaller

    INSTALL_DIR="$PFY_CORE"
    export INSTALL_DIR

    echo -e " \e[1;32m[✔]\e[0m Migration complete."
    return 0
}
