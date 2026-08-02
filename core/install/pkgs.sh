#!/bin/bash

is_installed() {
    command -v "$1" >/dev/null 2>&1
}

install_dependencies() {
    local skip_power="${1:-false}"
    echo -e "\033[1;34m[*] \033[32mUpdating package list...\033[0m"
    
    case $PKG_MNGR in
        pkg) pkg update -y || return 1 ;;
        apt) $SUDO apt update -y || return 1 ;;
        pacman) $SUDO pacman -Sy --noconfirm || return 1 ;;
        dnf) $SUDO dnf check-update -y || true ;;
        zypper) $SUDO zypper refresh || return 1 ;;
        apk) $SUDO apk update || return 1 ;;
        brew) brew update || return 1 ;;
        unknown) echo -e "\e[1;33m[!] Unknown package manager. Skipping update...\e[0m" ;;
    esac

    echo -e "\033[1;34m[*] \033[32mChecking and installing dependencies...\033[0m"

    # Base Packages
    local base_pkgs=("figlet" "git" "zsh")
    for pkg in "${base_pkgs[@]}"; do
        if ! is_installed "$pkg"; then
            echo -e "\033[1;34m[*] \033[32mInstalling $pkg...\033[0m"
            install_single_pkg "$pkg"
        fi
    done

    # Terminal Helpers (package name varies by manager)
    if ! is_installed tput; then
        local tput_pkg="ncurses"
        case $PKG_MNGR in
            pkg) tput_pkg="ncurses-utils" ;;
            apt) tput_pkg="ncurses-bin" ;;
        esac
        install_single_pkg "$tput_pkg"
    fi

    # Termux Specifics
    if [[ "$OS_TYPE" == "termux" ]]; then
        for tpkg in "termux-api" "termux-tools"; do
             if ! is_installed "$tpkg"; then
                 pkg install "$tpkg" -y
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
            gem install lolcat --no-document || echo "Lolcat gem fail"
        else
            case $PKG_MNGR in
                apt) install_single_pkg "lolcat" ;;
                pacman) install_single_pkg "lolcat" ;;
                dnf) install_single_pkg "lolcat" ;;
                zypper) install_single_pkg "lolcat" ;;
                apk) install_single_pkg "lolcat" ;;
                brew) install_single_pkg "lolcat" ;;
                *) 
                    echo -e "\033[1;34m[*] \033[32mInstalling lolcat via gem...\033[0m"
                    if ! is_installed ruby; then
                        install_single_pkg "ruby"
                    fi
                    $SUDO gem install lolcat --no-document || echo "Lolcat gem fail"
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
            choices=$(checkbox_menu "Select Power Tools to Install" "${opts[@]}")
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

    return 0
}

install_single_pkg() {
    local pkg="$1"
    echo -e "\033[1;34m[*] \033[32mInstalling $pkg...\033[0m"
    case $PKG_MNGR in
        pkg) pkg install "$pkg" -y ;;
        apt) $SUDO apt install "$pkg" -y ;;
        pacman) $SUDO pacman -S --noconfirm "$pkg" ;;
        dnf) $SUDO dnf install -y "$pkg" ;;
        zypper) $SUDO zypper install -y "$pkg" ;;
        apk) $SUDO apk add "$pkg" ;;
        emerge) $SUDO emerge --ask n "$pkg" ;;
        brew) brew install "$pkg" ;;
    esac
}

install_power_tools() {
    echo -e "\033[1;34m[*] \033[32mInstalling Others (Eza, Bat)...\033[0m"
    if ! is_installed eza && ! is_installed exa; then
        install_single_pkg "eza"
    else
        echo -e "\033[1;34m[*] \033[32mEza/Exa already present.\033[0m"
    fi
    if ! is_installed bat && ! is_installed batcat; then
        install_single_pkg "bat"
    else
        echo -e "\033[1;34m[*] \033[32mBat already present.\033[0m"
    fi
}

sync_assets() {
    echo -e "\033[1;34m[*] \033[32mSyncing UI Assets...\033[0m"
    local asset_dir="$INSTALL_DIR/assets"
    
    # Bundled banner fonts (shadow + the extra lowercase-capable styles)
    local bundled_fonts=("ASCII-Shadow.flf" "slant.flf" "banner.flf" "smpoison.flf" "graffiti.flf")
    
    # Create asset dir
    mkdir -p "$SYS_DIR/assets"

    # Copy to Home
    cp "$asset_dir/ASCII-Shadow.flf" "$HOME/.promptify_font.flf" 2>/dev/null || true
    chmod 644 "$HOME/.promptify_font.flf" 2>/dev/null || true

    # Copy to System (including the .draw banner renderer so dep_status can heal)
    for font_file in "${bundled_fonts[@]}"; do
        cp "$asset_dir/$font_file" "$SYS_DIR/assets/" 2>/dev/null || true
    done
    cp "$asset_dir/.draw" "$SYS_DIR/assets/.draw" 2>/dev/null || true
    cp "$asset_dir/termux.properties" "$SYS_DIR/assets/" 2>/dev/null || true
    cp "$asset_dir/colors.properties" "$SYS_DIR/assets/" 2>/dev/null || true
    cp "$asset_dir/font.ttf" "$SYS_DIR/assets/" 2>/dev/null || true

    # Refresh the live banner renderer only if the banner is currently enabled
    if [[ -f "$HOME/.draw" ]]; then
        cp "$asset_dir/.draw" "$HOME/.draw" 2>/dev/null || true
        chmod +x "$HOME/.draw" 2>/dev/null || true
    fi

    # PC: install Nerd Font + auto-set in common desktop terminals
    if [[ "$OS_TYPE" != "termux" ]]; then
        apply_desktop_font
    fi

    if [[ "$OS_TYPE" == "termux" ]]; then
        mkdir -p "$HOME/.termux"
        
        # Backup old settings
        backup_file "$HOME/.termux/colors.properties"
        backup_file "$HOME/.termux/font.ttf"
        backup_file "$HOME/.termux/termux.properties"

        cp "$asset_dir/colors.properties" "$HOME/.termux/" 2>/dev/null || true
        cp "$asset_dir/font.ttf" "$HOME/.termux/" 2>/dev/null || true
        
        # Handle Android versions
        local major_ver
        major_ver=$(echo "$ANDROID_VER" | grep -oE '^[0-9]+' || echo "0")
        if [[ "$major_ver" -gt 0 && "$major_ver" -le 7 ]]; then
            cp "$asset_dir/termux.properties2" "$HOME/.termux/termux.properties" 2>/dev/null || true
        else
            cp "$asset_dir/termux.properties" "$HOME/.termux/" 2>/dev/null || true
        fi
        
        # Install figlet fonts
        mkdir -p "$PREFIX/share/figlet"
        for font_file in "${bundled_fonts[@]}"; do
            cp "$asset_dir/$font_file" "$PREFIX/share/figlet/" 2>/dev/null || true
        done
    fi
}
