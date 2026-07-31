#!/bin/bash

FONT_NAME="JetBrainsMono Nerd Font"

# Install Nerd Font to user fonts dir for desktop terminals
install_user_font() {
    local font_dir="$HOME/.local/share/fonts"
    mkdir -p "$font_dir" 2>/dev/null || true
    cp "$INSTALL_DIR/assets/font.ttf" "$font_dir/JetBrainsMonoNerdFont-Regular.ttf" 2>/dev/null || true
    command -v fc-cache &>/dev/null && fc-cache -f "$font_dir" >/dev/null 2>&1 || true
}

# Set or append a key=value line in a config file
set_terminal_font_line() {
    local file="$1"
    local pattern="$2"
    local value="$3"
    if grep -qE "$pattern" "$file" 2>/dev/null; then
        sed_i -E "s/$pattern/$value/" "$file" 2>/dev/null
    else
        echo "$value" >> "$file"
    fi
}

# Auto-set JetBrainsMono Nerd Font in common desktop terminals
configure_terminal_font() {
    # Kitty
    if command -v kitty &>/dev/null || [[ -d "$HOME/.config/kitty" ]]; then
        mkdir -p "$HOME/.config/kitty"
        local kc="$HOME/.config/kitty/kitty.conf"
        [[ -f "$kc" ]] || touch "$kc"
        set_terminal_font_line "$kc" '^font_family.*' "font_family $FONT_NAME"
    fi

    # Alacritty (toml, fallback yml)
    local alc=""
    [[ -f "$HOME/.config/alacritty/alacritty.toml" ]] && alc="$HOME/.config/alacritty/alacritty.toml"
    [[ -f "$HOME/.config/alacritty/alacritty.yml" ]] && alc="$HOME/.config/alacritty/alacritty.yml"
    if [[ -n "$alc" ]]; then
        if grep -q '^\[font' "$alc" 2>/dev/null; then
            sed_i -E 's/^family = .*/family = "'"$FONT_NAME"'"/' "$alc" 2>/dev/null
        else
            printf '\n[font.normal]\nfamily = "%s"\n' "$FONT_NAME" >> "$alc"
        fi
    fi

    # GNOME Terminal
    if command -v gsettings &>/dev/null; then
        local prof
        prof=$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'")
        if [[ -n "$prof" && "$prof" != "[]" ]]; then
            gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$prof/" font "$FONT_NAME 12" 2>/dev/null || true
        fi
    fi

    # Konsole
    if command -v konsole &>/dev/null || [[ -d "$HOME/.local/share/konsole" ]]; then
        local p
        for p in "$HOME"/.local/share/konsole/*.profile; do
            [[ -f "$p" ]] || continue
            if grep -q '^Font=' "$p" 2>/dev/null; then
                sed_i 's/^Font=.*/Font='"$FONT_NAME"',12/' "$p" 2>/dev/null
            else
                printf '\n[General]\nFont=%s,12\n' "$FONT_NAME" >> "$p"
            fi
        done
    fi

    # XFCE4 Terminal
    if [[ -f "$HOME/.config/xfce4/terminal/terminalrc" ]]; then
        set_terminal_font_line "$HOME/.config/xfce4/terminal/terminalrc" '^FontName=.*' "FontName=$FONT_NAME 12"
    fi
}

# Entry point for non-Termux: install font + apply to terminals
apply_desktop_font() {
    install_user_font
    configure_terminal_font
}
