#!/bin/bash

uninstall_promptify() {
    if ! is_promptify_installed && [[ ! -d "$SYS_DIR" ]]; then
        echo -e "\n \e[1;33m[!] Promptify is not installed or already removed.\e[0m"
        press_enter
        return
    fi

    # If the self-contained uninstaller exists, prefer it: it restores the
    # snapshot even if the program files are gone, then removes everything.
    if [[ -f "$PFY_UNINSTALLER" ]]; then
        if confirm_action "Run the self-contained uninstaller (recommended)? This fully restores your system." "y"; then
            clear
            bash "$PFY_UNINSTALLER"
            press_enter
            exit 0
        fi
    fi

    # Load what install recorded so uninstall can reverse it exactly
    read_install_state

    # Auto-detect components for checkboxes. The original config restore is
    # always done (it is the whole point of the snapshot), so it isn't a
    # checkbox.
    local ui_sel=""
    if has_termux_ui_changes || has_bundled_figlet_fonts || [[ "$DESKTOP_FONT" == "1" ]]; then
        ui_sel="|selected"
    fi

    local asset_sel=""
    [[ -f "$HOME/.draw" || -f "$HOME/.username" ]] && asset_sel="|selected"

    local opts=(
        "Revert Terminal UI Settings$ui_sel"
        "Remove Home Assets$asset_sel"
        "Remove Promptify System Directory|selected"
    )

    # Build Dynamic Menu Options (UI cleanup before dir removal so figlet
    # backups living inside $SYS_DIR are still readable)
    local choices
    choices=$(checkbox_menu "Uninstall Management" "" "${opts[@]}")

    [[ "$choices" == "CANCELLED" || -z "$choices" ]] && return

    if ! confirm_action "Are you sure you want to proceed with uninstallation?" "n"; then
        return
    fi

    echo -e "\n\e[1;34m[*] Starting uninstallation process...\e[0m"

    # 1. Time-travel: restore the original shell config FIRST (the snapshot
    #    lives inside $SYS_DIR, so it must be read before the directory goes).
    if [[ -f "$PFY_MANIFEST" ]]; then
        center_print "\e[1;34m[*] \e[0mRestoring your original config from the install snapshot..."
        restore_snapshot
    else
        # Legacy inline-block install (no snapshot) — strip the old markers.
        clean_shell_profile
    fi

    # 2. Run the user's chosen cleanup (UI before directory removal)
    local action
    for choice in $choices; do
        case "$choice" in
            0) clean_ui_settings ;;
            1) clean_assets ;;
            2) clean_sys_dir ;;
        esac
    done

    # 3. Restore pre-install shell — only offered when the current default
    #    shell actually differs from what we recorded before install.
    local target_shell="${PRE_SHELL:-bash}"
    local cur_shell
    if [[ "$OS_TYPE" == "termux" ]]; then
        cur_shell=$(readlink -f "$HOME/.termux/shell" 2>/dev/null || echo "${SHELL:-}")
    else
        cur_shell=$(getent passwd "$(whoami)" 2>/dev/null | cut -d: -f7)
        [[ -z "$cur_shell" ]] && cur_shell="${SHELL:-}"
    fi
    if [[ "${cur_shell##*/}" != "${target_shell##*/}" ]]; then
        if confirm_action "Restore default shell to '${target_shell##*/}'?" "y"; then
            restore_shell "$target_shell"
        fi
    fi

    # 4. Full verification
    verify_cleanup
    center_print "\e[1;32m[✔] Cleanup Complete!\e[0m"

    press_enter
}

# Did install record that it touched the Termux UI (or is a file present that
# only Promptify creates there)?
has_termux_ui_changes() {
    [[ "$TERMUX_UI" == "1" ]] && return 0
    [[ "$OS_TYPE" == "termux" ]] || return 1
    local f
    for f in "$HOME/.termux/colors.properties" "$HOME/.termux/font.ttf"; do
        [[ -f "$f" ]] && return 0
    done
    return 1
}

# Any bundled figlet font present (either the originals we overwrote are
# backed up, or our copies are installed)?
has_bundled_figlet_fonts() {
    local dir
    dir=$(figlet_font_dirs)
    [[ -d "$dir" ]] || return 1
    local f
    for f in "${BUNDLED_FONTS[@]}"; do
        [[ -f "$dir/$f" ]] && return 0
    done
    return 1
}

clean_shell_profile() {
    # Clean ~/.zshrc
    if [[ -f "$HOME/.zshrc" ]]; then
        center_print "\e[1;34m[*] \e[0mCleaning ~/.zshrc..."
        sed_i -e '/# --- Promptify Config ---/,/# --- End Promptify Config ---/d' \
              -e '/PROMPTIFY_DIR/d' \
              -e '/build_prompt/d' \
              -e '/alias Promptify=/d' \
              -e '/alias pty=/d' "$HOME/.zshrc" 2>/dev/null

        if [[ -f "$HOME/.zshrc.bak" ]]; then
            center_print "\e[1;34m[*] \e[0mRestoring original ~/.zshrc..."
            mv "$HOME/.zshrc.bak" "$HOME/.zshrc"
            sed_i '/# --- Promptify Config ---/,/# --- End Promptify Config ---/d' "$HOME/.zshrc" 2>/dev/null
        fi
    fi
    rm -f "$HOME/.zshrc.bak" "$HOME/.zshrc.pre-promptify"

    # Remove ~/.zshrc entirely if Promptify created it (pre-install state)
    if [[ "$HAD_ZSHRC" == "0" && -f "$HOME/.zshrc" ]] && ! grep -q '[^[:space:]]' "$HOME/.zshrc" 2>/dev/null; then
        rm -f "$HOME/.zshrc"
    fi

    # Clean ~/.bashrc (same treatment: marker strip, .bak restore)
    if [[ -f "$HOME/.bashrc" ]]; then
        center_print "\e[1;34m[*] \e[0mCleaning ~/.bashrc..."
        sed_i '/# --- Promptify Config ---/,/# --- End Promptify Config ---/d' "$HOME/.bashrc" 2>/dev/null

        if [[ -f "$HOME/.bashrc.bak" ]]; then
            center_print "\e[1;34m[*] \e[0mRestoring original ~/.bashrc..."
            mv "$HOME/.bashrc.bak" "$HOME/.bashrc"
            sed_i '/# --- Promptify Config ---/,/# --- End Promptify Config ---/d' "$HOME/.bashrc" 2>/dev/null
        fi
    fi
    rm -f "$HOME/.bashrc.bak"

    if [[ "$HAD_BASHRC" == "0" && -f "$HOME/.bashrc" ]] && ! grep -q '[^[:space:]]' "$HOME/.bashrc" 2>/dev/null; then
        rm -f "$HOME/.bashrc"
    fi
}

clean_sys_dir() {
    # Use a pretty path for display (~/.promptify)
    local display_path="${SYS_DIR/#$HOME/\~}"
    center_print "\e[1;34m[*] \e[0mRemoving system directory ($display_path)..."
    rm -rf "$SYS_DIR"

    # Remove global binary
    local bin_path="/usr/local/bin/promptify"
    [[ "$OS_TYPE" == "termux" ]] && bin_path="$PREFIX/bin/promptify"

    if [[ -f "$bin_path" ]]; then
        center_print "\e[1;34m[*] \e[0mRemoving global command..."
        if [[ "$OS_TYPE" == "termux" ]]; then
            rm -f "$bin_path" 2>/dev/null
        else
            $SUDO rm -f "$bin_path" 2>/dev/null
        fi
    fi
}

clean_ui_settings() {
    if [[ "$OS_TYPE" == "termux" ]]; then
        center_print "\e[1;34m[*] \e[0mReverting Termux UI settings..."
        local files=("font.ttf" "colors.properties" "termux.properties")
        local f
        for f in "${files[@]}"; do
            if [[ -f "$HOME/.termux/${f}.bak" ]]; then
                mv "$HOME/.termux/${f}.bak" "$HOME/.termux/${f}"
            elif [[ -f "$HOME/.termux/${f}" ]]; then
                # Only remove a file we actually installed — a user's own
                # termux.properties (or any custom file) must be left alone.
                if cmp -s "$HOME/.termux/${f}" "$INSTALL_DIR/assets/${f}" 2>/dev/null \
                || cmp -s "$HOME/.termux/${f}" "$INSTALL_DIR/assets/termux.properties2" 2>/dev/null \
                || file_matches_fingerprint "$HOME/.termux/${f}"; then
                    rm -f "$HOME/.termux/${f}"
                fi
            fi
        done
        termux-reload-settings 2>/dev/null || true
    fi

    # Restore bundled figlet fonts (never removes the package's own fonts)
    remove_bundled_figlet_fonts

    if [[ "$OS_TYPE" != "termux" ]]; then
        clean_desktop_font
    fi
}

clean_assets() {
    center_print "\e[1;34m[*] \e[0mCleaning local assets..."
    rm -f "$HOME/.draw" "$HOME/.username" "$HOME/.promptify_font.flf"
}

# Remove the Nerd Font and undo terminal config edits made by configure_terminal_font
clean_desktop_font() {
    center_print "\e[1;34m[*] \e[0mRemoving desktop font changes..."

    # Remove the font we installed (only if it still matches our asset or a
    # recorded fingerprint)
    local font_file="$HOME/.local/share/fonts/JetBrainsMonoNerdFont-Regular.ttf"
    if [[ -f "$font_file" ]] && { cmp -s "$font_file" "$INSTALL_DIR/assets/font.ttf" 2>/dev/null || file_matches_fingerprint "$font_file"; }; then
        rm -f "$font_file"
        command -v fc-cache &>/dev/null && fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1 || true
    fi

    # Kitty: restore backup, else strip our line + drop file if empty
    local kc="$HOME/.config/kitty/kitty.conf"
    if [[ -f "$kc.bak" ]]; then
        mv -f "$kc.bak" "$kc"
    elif [[ -f "$kc" ]]; then
        sed_i '/^font_family JetBrainsMono Nerd Font$/d' "$kc" 2>/dev/null
        remove_if_empty "$kc"
    fi

    # Alacritty
    local alc=""
    [[ -f "$HOME/.config/alacritty/alacritty.toml" ]] && alc="$HOME/.config/alacritty/alacritty.toml"
    [[ -f "$HOME/.config/alacritty/alacritty.yml" ]] && alc="$HOME/.config/alacritty/alacritty.yml"
    if [[ -n "$alc" && -f "${alc}.bak" ]]; then
        mv -f "${alc}.bak" "$alc"
    elif [[ -n "$alc" && -f "$alc" ]]; then
        sed_i -e '/^\[font\.normal\]$/,/^$/d' -e '/^family = "JetBrainsMono Nerd Font"$/d' "$alc" 2>/dev/null
        remove_if_empty "$alc"
    fi

    # Konsole profiles
    local p
    for p in "$HOME"/.local/share/konsole/*.profile; do
        [[ -f "$p" ]] || continue
        if [[ -f "$p.bak" ]]; then
            mv -f "$p.bak" "$p"
        else
            sed_i '/^Font=JetBrainsMono Nerd Font,12$/d' "$p" 2>/dev/null
            remove_if_empty "$p"
        fi
    done

    # XFCE4 Terminal
    local xfce="$HOME/.config/xfce4/terminal/terminalrc"
    if [[ -f "$xfce.bak" ]]; then
        mv -f "$xfce.bak" "$xfce"
    elif [[ -f "$xfce" ]]; then
        sed_i '/^FontName=JetBrainsMono Nerd Font 12$/d' "$xfce" 2>/dev/null
        remove_if_empty "$xfce"
    fi
}

# Delete a file if nothing but whitespace remains
remove_if_empty() {
    local file="$1"
    [[ -f "$file" ]] || return 0
    if ! grep -q '[^[:space:]]' "$file" 2>/dev/null; then
        rm -f "$file"
    fi
}

# Restore the default shell that existed before install (falls back to bash)
restore_shell() {
    local target="${1:-${PRE_SHELL:-bash}}"
    local base="${target##*/}"

    # Resolve bare names to full paths
    case "$target" in
        */*) ;;
        *) target=$(command -v "$target" 2>/dev/null || echo "$target") ;;
    esac

    if [[ "$OS_TYPE" == "termux" ]]; then
        if command -v chsh &>/dev/null; then
            chsh -s "$target" 2>/dev/null || chsh -s "$base" 2>/dev/null || true
        fi
        # chsh on Termux manages ~/.termux/shell; if it missed, set it directly
        if [[ -e "$HOME/.termux/shell" || -L "$HOME/.termux/shell" ]]; then
            rm -f "$HOME/.termux/shell"
            if [[ -x "$target" ]]; then
                ln -s "$target" "$HOME/.termux/shell" 2>/dev/null || true
            fi
        fi
    else
        $SUDO chsh -s "$target" "$(whoami)" &> /dev/null || true
    fi

    center_print "\e[1;32m[✔] \033[0mDefault shell restored to ${base}."
}
