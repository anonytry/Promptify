#!/bin/bash

# Set OS_TYPE / PKG_MNGR / OS_NAME from an os-release file (path overridable for tests).
detect_from_os_release() {
    local osrel="${1:-/etc/os-release}"
    OS_NAME=$(grep "^PRETTY_NAME=" "$osrel" | cut -d= -f2- | tr -d '"' | tr -d "'")
    [[ -z "$OS_NAME" ]] && OS_NAME=$(grep "^ID=" "$osrel" | head -1 | cut -d= -f2- | tr -d '"' | tr -d "'")

    # ID / ID_LIKE tolerate quotes and multiple space-separated values
    local os_id os_like
    os_id=$(grep -E '^ID=' "$osrel" | head -1 | cut -d= -f2- | tr -d '"' | tr -d "'")
    os_like=$(grep -E '^ID_LIKE=' "$osrel" | head -1 | cut -d= -f2- | tr -d '"' | tr -d "'")
    case "$os_id $os_like" in
        *ubuntu*|*debian*|*kali*) OS_TYPE="debian"; PKG_MNGR="apt" ;;
        *arch*) OS_TYPE="arch"; PKG_MNGR="pacman" ;;
        *fedora*|*centos*|*rhel*) OS_TYPE="fedora"; PKG_MNGR="dnf" ;;
        *opensuse*|*suse*) OS_TYPE="suse"; PKG_MNGR="zypper" ;;
        *gentoo*) OS_TYPE="gentoo"; PKG_MNGR="emerge" ;;
        *alpine*) OS_TYPE="alpine"; PKG_MNGR="apk" ;;
        *void*) OS_TYPE="void"; PKG_MNGR="xbps" ;;
        *slackware*) OS_TYPE="slackware"; PKG_MNGR="slackpkg" ;;
        *) OS_TYPE="linux"; PKG_MNGR="unknown" ;;
    esac
}

# Fallback when os-release is missing or unrecognized: detect the package
# manager from whichever one is actually installed on this machine.
detect_pm_from_binaries() {
    if command -v pacman &>/dev/null; then
        PKG_MNGR="pacman"; [[ "$OS_TYPE" == "linux" ]] && OS_TYPE="arch"
    elif command -v apt-get &>/dev/null || command -v dpkg &>/dev/null; then
        PKG_MNGR="apt"; [[ "$OS_TYPE" == "linux" ]] && OS_TYPE="debian"
    elif command -v dnf &>/dev/null; then
        PKG_MNGR="dnf"; [[ "$OS_TYPE" == "linux" ]] && OS_TYPE="fedora"
        elif command -v zypper &>/dev/null; then
            PKG_MNGR="zypper"; [[ "$OS_TYPE" == "linux" ]] && OS_TYPE="suse"
        elif command -v xbps-install &>/dev/null; then
            PKG_MNGR="xbps"; [[ "$OS_TYPE" == "linux" ]] && OS_TYPE="void"
        elif command -v slackpkg &>/dev/null; then
            PKG_MNGR="slackpkg"; [[ "$OS_TYPE" == "linux" ]] && OS_TYPE="slackware"
        elif command -v apk &>/dev/null; then
        PKG_MNGR="apk"; [[ "$OS_TYPE" == "linux" ]] && OS_TYPE="alpine"
    elif command -v emerge &>/dev/null; then
        PKG_MNGR="emerge"; [[ "$OS_TYPE" == "linux" ]] && OS_TYPE="gentoo"
    elif command -v brew &>/dev/null; then
        PKG_MNGR="brew"
    fi
}

detect_env() {
    ANDROID_VER=""
    KERNEL_VER=$(uname -r)
    ARCH=$(uname -m)
    
    SUDO=""
    if [[ "$(id -u)" -ne 0 ]]; then
        if command -v sudo &>/dev/null; then
            SUDO="sudo"
        elif command -v doas &>/dev/null; then
            SUDO="doas"
        fi
    fi

    # Order matters: Termux wins only when there is no /etc/os-release
    # (inside proot-distro the os-release belongs to the guest distro).
    if [[ -d "/data/data/com.termux/files/usr/bin" ]] && [[ ! -f /etc/os-release ]]; then
        OS_TYPE="termux"
        OS_NAME="Termux"
        PKG_MNGR="pkg"
        ANDROID_VER=$(getprop ro.build.version.release 2>/dev/null || echo "Unknown")
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="darwin"
        OS_NAME="macOS"
        PKG_MNGR="brew"
        SUDO=""
        [[ "$(id -u)" -ne 0 ]] && SUDO="sudo"
    elif [[ -f /etc/os-release ]]; then
        detect_from_os_release /etc/os-release
    else
        OS_TYPE="linux"
        OS_NAME="Linux"
        PKG_MNGR="unknown"
    fi

    # Fallback: os-release missing or unrecognized? Detect the package manager
    # from whichever one is actually installed on this machine.
    if [[ "$PKG_MNGR" == "unknown" ]]; then
        detect_pm_from_binaries
    fi

    export OS_TYPE OS_NAME PKG_MNGR SUDO ANDROID_VER KERNEL_VER ARCH
}
