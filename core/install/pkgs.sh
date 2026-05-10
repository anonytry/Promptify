#!/bin/bash

is_installed() {
    command -v "$1" >/dev/null 2>&1
}

install_dependencies() {
    echo -e "\033[1;34m[*] \033[32mUpdating package list...\033[0m"
    
    case $PKG_MNGR in
        pkg) pkg update -y || return 1 ;;
        apt) $SUDO apt update -y || return 1 ;;
        pacman) $SUDO pacman -Sy --noconfirm || return 1 ;;
        dnf) $SUDO dnf check-update -y; [[ $? -eq 100 ]] && true || return 1 ;;
        zypper) $SUDO zypper refresh || return 1 ;;
        apk) $SUDO apk update || return 1 ;;
        brew) brew update || return 1 ;;
    esac

    echo -e "\033[1;34m[*] \033[32mChecking and installing dependencies...\033[0m"

    # Base Packages
    local base_pkgs=("figlet" "ruby" "git" "zsh")
    for pkg in "${base_pkgs[@]}"; do
        if ! is_installed "$pkg"; then
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
        fi
    done

    # Terminal Helpers (ncurses)
    if ! is_installed tput; then
        case $PKG_MNGR in
            pkg) pkg install ncurses-utils -y ;;
            apt) $SUDO apt install ncurses-bin -y ;;
            pacman) $SUDO pacman -S --noconfirm ncurses ;;
            dnf) $SUDO dnf install -y ncurses ;;
            zypper) $SUDO zypper install -y ncurses ;;
            apk) $SUDO apk add ncurses ;;
            brew) brew install ncurses ;;
        esac
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
        case $PKG_MNGR in
            apt) $SUDO apt install lolcat -y ;;
            pacman) $SUDO pacman -S --noconfirm lolcat ;;
            dnf) $SUDO dnf install -y lolcat ;;
            zypper) $SUDO zypper install -y lolcat ;;
            apk) $SUDO apk add lolcat ;;
            brew) brew install lolcat ;;
            *) 
                echo -e "\033[1;34m[*] \033[32mInstalling lolcat via gem...\033[0m"
                if [[ "$OS_TYPE" == "termux" ]]; then
                    gem install lolcat --no-document || echo "Lolcat gem fail"
                else
                    $SUDO gem install lolcat --no-document || echo "Lolcat gem fail"
                fi
                ;;
        esac
    fi

    # eza / exa
    if ! is_installed eza && ! is_installed exa; then
        case $PKG_MNGR in
            pkg) pkg install eza -y ;;
            pacman) $SUDO pacman -S --noconfirm eza ;;
            dnf) $SUDO dnf install -y eza ;;
            zypper) $SUDO zypper install -y eza ;;
            apk) $SUDO apk add eza ;;
            brew) brew install eza ;;
            apt) 
                if $SUDO apt install eza -y 2>/dev/null; then
                    :
                else
                    echo -e "\033[1;33m[!] eza not found in apt repos, trying exa...\033[0m"
                    $SUDO apt install exa -y 2>/dev/null || echo -e "\033[1;31m[!] Could not install eza or exa via apt.\033[0m"
                fi
                ;;
        esac
    fi

    # bat / batcat
    if ! is_installed bat && ! is_installed batcat; then
        case $PKG_MNGR in
            pkg) pkg install bat -y ;;
            pacman) $SUDO pacman -S --noconfirm bat ;;
            dnf) $SUDO dnf install -y bat ;;
            zypper) $SUDO zypper install -y bat ;;
            apk) $SUDO apk add bat ;;
            brew) brew install bat ;;
            apt) 
                $SUDO apt install bat -y 2>/dev/null || echo -e "\033[1;31m[!] Could not install bat via apt.\033[0m"
                ;;
        esac
    fi

    return 0
}

sync_assets() {
    echo -e "\033[1;34m[*] \033[32mSyncing UI Assets...\033[0m"
    local asset_dir="$INSTALL_DIR/assets"
    
    # Ensure system asset dir exists
    mkdir -p "$SYS_DIR/assets"

    # Copy to Home for direct usage
    cp "$asset_dir/ASCII-Shadow.flf" "$HOME/.promptify_font.flf" 2>/dev/null || true
    chmod 644 "$HOME/.promptify_font.flf" 2>/dev/null || true

    # Copy to System Dir for persistence
    cp "$asset_dir/ASCII-Shadow.flf" "$SYS_DIR/assets/" 2>/dev/null || true
    cp "$asset_dir/termux.properties" "$SYS_DIR/assets/" 2>/dev/null || true
    cp "$asset_dir/colors.properties" "$SYS_DIR/assets/" 2>/dev/null || true
    cp "$asset_dir/font.ttf" "$SYS_DIR/assets/" 2>/dev/null || true

    if [[ "$OS_TYPE" == "termux" ]]; then
        mkdir -p "$HOME/.termux"
        
        # Back up existing settings before overwriting
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
        
        # Copy figlet font to standard path
        mkdir -p "$PREFIX/share/figlet"
        cp "$asset_dir/ASCII-Shadow.flf" "$PREFIX/share/figlet/" 2>/dev/null || true
    fi
}
