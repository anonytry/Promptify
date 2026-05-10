#!/bin/bash

detect_env() {
    ANDROID_VER=""
    KERNEL_VER=$(uname -r)
    ARCH=$(uname -m)
    
    if [[ -f /etc/os-release ]]; then
        OS_NAME=$(grep "^PRETTY_NAME=" /etc/os-release | cut -d= -f2 | tr -d '"')
        [[ -z "$OS_NAME" ]] && OS_NAME=$(grep "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
        
        SUDO=""
        if [[ "$(id -u)" -ne 0 ]]; then
            if command -v sudo &>/dev/null; then
                SUDO="sudo"
            elif command -v doas &>/dev/null; then
                SUDO="doas"
            fi
        fi

        if grep -qiE "^ID=(ubuntu|debian|kali)$|^ID_LIKE=(ubuntu|debian)" /etc/os-release; then
             OS_TYPE="debian"
             PKG_MNGR="apt"
        elif grep -qiE "^ID=arch$|^ID_LIKE=arch" /etc/os-release; then
             OS_TYPE="arch"
             PKG_MNGR="pacman"
        elif grep -qiE "^ID=(fedora|centos|rhel)$|^ID_LIKE=(fedora|centos|rhel)" /etc/os-release; then
             OS_TYPE="fedora"
             PKG_MNGR="dnf"
        elif grep -qiE "^ID=(opensuse|suse)$|^ID_LIKE=(opensuse|suse)" /etc/os-release; then
             OS_TYPE="suse"
             PKG_MNGR="zypper"
        elif grep -qiE "^ID=gentoo$|^ID_LIKE=gentoo" /etc/os-release; then
             OS_TYPE="gentoo"
             PKG_MNGR="emerge"
        elif grep -qiE "^ID=alpine$|^ID_LIKE=alpine" /etc/os-release; then
             OS_TYPE="alpine"
             PKG_MNGR="apk"
        else
             OS_TYPE="linux"
             PKG_MNGR="unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="darwin"
        OS_NAME="macOS"
        PKG_MNGR="brew"
        SUDO=""
        [[ "$(id -u)" -ne 0 ]] && SUDO="sudo"
    elif [[ -d "/data/data/com.termux/files/usr/bin" ]]; then
        OS_TYPE="termux"
        OS_NAME="Termux"
        PKG_MNGR="pkg"
        SUDO=""
        ANDROID_VER=$(getprop ro.build.version.release 2>/dev/null || echo "Unknown")
    else
        OS_TYPE="linux"
        OS_NAME="Linux"
        PKG_MNGR="unknown"
        SUDO=""
    fi

    export OS_TYPE OS_NAME PKG_MNGR SUDO ANDROID_VER KERNEL_VER ARCH
}
