#!/bin/bash

is_installed() {
    command -v "$1" >/dev/null 2>&1
}

install_dependencies() {
    local skip_power="${1:-false}"
    
    # --- Admin access check: fail loudly & early if we can't elevate. Only for
    # system package managers (Termux's pkg and Homebrew don't need root) ---
    case "$PKG_MNGR" in
        apt|pacman|dnf|zypper|apk|emerge|xbps|slackpkg)
            if [[ "$(id -u)" -ne 0 ]]; then
                if [[ -z "$SUDO" ]]; then
                    echo -e "\e[1;31m[✗] Dependencies need root, but no 'sudo' or 'doas' was found.\e[0m"
                    echo -e "\e[1;33m    Install sudo as root (Arch: 'pacman -S sudo') and add your user to the wheel group, then re-run.\e[0m"
                    return 1
                fi
                sudo_notice "Installing system dependencies"
                if [[ "$SUDO" == "sudo" ]]; then
                    $SUDO -v || {
                        echo -e "\e[1;31m[✗] Admin (sudo) access is required to install dependencies.\e[0m"
                        echo -e "\e[1;33m    Your user must be allowed to sudo (e.g. add to the 'wheel' group: usermod -aG wheel ${USER}), then log out and back in.\e[0m"
                        return 1
                    }
                else
                    $SUDO true || {
                        echo -e "\e[1;31m[✗] Admin (doas) access is required to install dependencies.\e[0m"
                        return 1
                    }
                fi
            fi
            ;;
    esac

    echo -e "\033[1;34m[*] \033[32mUpdating package list...\033[0m"
    
    case $PKG_MNGR in
        pkg) pkg update -y || return 1 ;;
        apt) $SUDO apt update -y || return 1 ;;
        pacman) $SUDO pacman -Sy --noconfirm || return 1 ;;
        dnf) $SUDO dnf check-update -y || true ;;
        zypper) $SUDO zypper refresh || return 1 ;;
        xbps) $SUDO xbps-install -S || return 1 ;;
        slackpkg) $SUDO slackpkg -batch=on -default_answer=y update || return 1 ;;
        apk) $SUDO apk update || return 1 ;;
        brew) brew update || return 1 ;;
        unknown) echo -e "\e[1;33m[!] Unknown package manager. Skipping update...\e[0m" ;;
    esac

    echo -e "\033[1;34m[*] \033[32mChecking and installing dependencies...\033[0m"

    # Base Packages
    local base_pkgs=("figlet" "git" "zsh")
    local dep_failed=false
    for pkg in "${base_pkgs[@]}"; do
        if ! is_installed "$pkg"; then
            echo -e "\033[1;34m[*] \033[32mInstalling $pkg...\033[0m"
            install_single_pkg "$pkg" || dep_failed=true
        fi
    done

    # Terminal Helpers (package name varies by manager)
    if ! is_installed tput; then
        local tput_pkg="ncurses"
        case $PKG_MNGR in
            pkg) tput_pkg="ncurses-utils" ;;
            apt) tput_pkg="ncurses-bin" ;;
            xbps) tput_pkg="ncurses" ;;
        esac
        install_single_pkg "$tput_pkg" || dep_failed=true
    fi

    # Termux Specifics
    if [[ "$OS_TYPE" == "termux" ]]; then
        for tpkg in "termux-api" "termux-tools"; do
             if ! is_installed "$tpkg"; then
                 install_single_pkg "$tpkg" || dep_failed=true
             fi
        done
    fi

    # lolcat
    if ! is_installed lolcat; then
        if [[ "$OS_TYPE" == "termux" ]]; then
            echo -e "\033[1;34m[*] \033[32mInstalling lolcat via gem (Termux)...\033[0m"
            if ! is_installed ruby; then
                install_single_pkg "ruby"
            fi
            # Termux Ruby needs the openssl package at runtime for gem HTTPS
            if ! is_installed openssl; then
                install_single_pkg "openssl"
            fi
            # If Ruby still can't load openssl, reinstall it to fix the linkage
            if ! ruby -e 'require "openssl"' &>/dev/null; then
                echo -e "\033[1;34m[*] \033[32mReinstalling Ruby with OpenSSL support...\033[0m"
                pkg reinstall ruby -y || pkg install ruby -y
            fi
            gem install lolcat --no-document \
                || echo -e "\e[1;33m[!] Could not install lolcat (optional, continuing without it).\e[0m"
        else
            case $PKG_MNGR in
                apt|pacman|dnf|zypper|apk|brew|xbps|slackpkg)
                    install_single_pkg "lolcat" \
                        || echo -e "\e[1;33m[!] Could not install lolcat (optional, continuing without it).\e[0m"
                    ;;
                *) 
                    echo -e "\033[1;34m[*] \033[32mInstalling lolcat via gem...\033[0m"
                    if ! is_installed ruby; then
                        install_single_pkg "ruby"
                    fi
                    $SUDO gem install lolcat --no-document \
                        || echo -e "\e[1;33m[!] Could not install lolcat (optional, continuing without it).\e[0m"
                    ;;
            esac
        fi
    fi

    # Optional Power Tools (skipped when the caller already offers them, e.g.
    # the Dependencies menu's separate "Others (Eza, Bat)" item)
    if [[ "$skip_power" == "true" ]]; then
        :
    elif [[ "$CONFIRM_ALL" == "false" ]]; then
        local opts=()
        local pkgs=()
        
        if ! is_installed eza && ! is_installed exa; then
            opts+=("Eza|selected")
            pkgs+=("eza")
        fi
        if ! is_installed bat && ! is_installed batcat; then
            opts+=("Bat|selected")
            pkgs+=("bat")
        fi

        if [[ ${#opts[@]} -gt 0 ]]; then
            echo -e "\n\e[1;34m[*] Optional Power Tools:\e[0m"
            local choices
            choices=$(checkbox_menu "Select Power Tools to Install" \
"Recommended: install both. Eza & Bat make 'ls' and 'cat' look nicer (icons, colors).
Skip for now? You can add them anytime later from Dependencies → Others." \
"${opts[@]}")
            if [[ "$choices" != "CANCELLED" ]]; then
                for idx in $choices; do
                    install_single_pkg "${pkgs[$idx]}"
                done
            fi
        fi
    else
        # Unattended defaults
        ! is_installed eza && ! is_installed exa && install_single_pkg "eza"
        ! is_installed bat && ! is_installed batcat && install_single_pkg "bat"
    fi

    if [[ "$dep_failed" == "true" ]]; then
        echo -e "\e[1;31m[✗] Some required packages failed to install (see messages above).\e[0m"
        return 1
    fi

    return 0
}

install_single_pkg() {
    local pkg="$1"
    echo -e "\033[1;34m[*] \033[32mInstalling $pkg...\033[0m"
    local cmd=()
    case $PKG_MNGR in
        pkg)     cmd=(pkg install "$pkg" -y) ;;
        apt)     cmd=($SUDO apt install "$pkg" -y) ;;
        pacman)  cmd=($SUDO pacman -S --noconfirm "$pkg") ;;
        dnf)     cmd=($SUDO dnf install -y "$pkg") ;;
        zypper)  cmd=($SUDO zypper install -y "$pkg") ;;
        xbps)    cmd=($SUDO xbps-install -y "$pkg") ;;
        slackpkg) cmd=($SUDO slackpkg -batch=on -default_answer=y install "$pkg") ;;
        apk)     cmd=($SUDO apk add "$pkg") ;;
        emerge)  cmd=($SUDO emerge --ask n "$pkg") ;;
        brew)    cmd=(brew install "$pkg") ;;
        *)
            echo -e "\e[1;31m[✗] No installer known for package manager '$PKG_MNGR'.\e[0m"
            return 1
            ;;
    esac

    if "${cmd[@]}"; then
        return 0
    fi

    echo -e "\e[1;31m[✗] Failed to install '$pkg'.\e[0m"
    echo -e "\e[1;33m    Command used: ${cmd[*]}\e[0m"
    echo -e "\e[1;33m    Fix: run it manually (add 'sudo' if needed), then re-run Promptify.\e[0m"
    return 1
}

install_power_tools() {
    echo -e "\033[1;34m[*] \033[32mInstalling Others (Eza, Bat)...\033[0m"
    local ok=true
    if is_installed eza || is_installed exa; then
        echo -e "\033[1;32m[✔] Eza/Exa already present.\033[0m"
    else
        install_single_pkg "eza" || ok=false
    fi
    if is_installed bat || is_installed batcat; then
        echo -e "\033[1;32m[✔] Bat already present.\033[0m"
    else
        install_single_pkg "bat" || ok=false
    fi
    [[ "$ok" == "true" ]]
}

sync_assets() {
    echo -e "\033[1;34m[*] \033[32mSyncing UI Assets...\033[0m"
    local asset_dir="$INSTALL_DIR/assets"
    local bundled_fonts=("ASCII-Shadow.flf" "slant.flf" "banner.flf" "smpoison.flf" "graffiti.flf")

    # Ensure the app dir (core/) has the assets
    mkdir -p "$PFY_CORE/assets"
    local font_file
    for font_file in "${bundled_fonts[@]}"; do
        cp "$asset_dir/$font_file" "$PFY_CORE/assets/" 2>/dev/null || true
    done
    cp "$asset_dir/.draw" "$PFY_CORE/assets/.draw" 2>/dev/null || true
    cp "$asset_dir/termux.properties" "$PFY_CORE/assets/" 2>/dev/null || true
    cp "$asset_dir/colors.properties" "$PFY_CORE/assets/" 2>/dev/null || true
    cp "$asset_dir/font.ttf" "$PFY_CORE/assets/" 2>/dev/null || true

    # Refresh the live banner renderer only if the banner is currently enabled
    if [[ -f "$HOME/.draw" ]]; then
        cp "$asset_dir/.draw" "$HOME/.draw" 2>/dev/null || true
        chmod +x "$HOME/.draw" 2>/dev/null || true
        snapshot_created "$HOME/.draw"
    fi

    # PC: install Nerd Font + auto-set in common desktop terminals
    if [[ "$OS_TYPE" != "termux" ]]; then
        apply_desktop_font
    fi

    if [[ "$OS_TYPE" == "termux" ]]; then
        mkdir -p "$HOME/.termux"
        snapshot_preserve "$HOME/.termux/colors.properties"
        snapshot_preserve "$HOME/.termux/font.ttf"
        snapshot_preserve "$HOME/.termux/termux.properties"

        cp "$asset_dir/colors.properties" "$HOME/.termux/" 2>/dev/null || true
        cp "$asset_dir/font.ttf" "$HOME/.termux/" 2>/dev/null || true

        local major_ver
        major_ver=$(echo "$ANDROID_VER" | grep -oE '^[0-9]+' || echo "0")
        if [[ "$major_ver" -gt 0 && "$major_ver" -le 7 ]]; then
            cp "$asset_dir/termux.properties2" "$HOME/.termux/termux.properties" 2>/dev/null || true
        else
            cp "$asset_dir/termux.properties" "$HOME/.termux/" 2>/dev/null || true
        fi

        snapshot_created "$HOME/.termux/colors.properties"
        snapshot_created "$HOME/.termux/font.ttf"
        snapshot_created "$HOME/.termux/termux.properties"

        # Install figlet fonts
        mkdir -p "$PREFIX/share/figlet"
        backup_bundled_figlet_fonts
        for font_file in "${bundled_fonts[@]}"; do
            cp "$asset_dir/$font_file" "$PREFIX/share/figlet/" 2>/dev/null || true
        done
    fi

    record_install_state
}
