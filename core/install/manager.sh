#!/bin/bash

# Best-effort list of packages with updates available, using only the local
# package-manager index (no network). Returns lines matching any of $@ names.
pkg_outdated_list() {
    local pkgs=("$@")
    local out=""
    case "$PKG_MNGR" in
        pkg)   out=$(timeout 5 apt list --upgradable 2>/dev/null) ;;
        apt)   out=$(timeout 5 $SUDO apt list --upgradable 2>/dev/null) ;;
        pacman) out=$(timeout 5 pacman -Qu 2>/dev/null) ;;
        dnf)   out=$(timeout 5 dnf list updates 2>/dev/null) ;;
        zypper) out=$(timeout 5 zypper list-updates 2>/dev/null) ;;
        apk)   out=$(timeout 5 apk info -u 2>/dev/null) ;;
        brew)  out=$(timeout 5 brew outdated 2>/dev/null) ;;
    esac
    for p in "${pkgs[@]}"; do
        grep -qiE "(^|[[:space:]/])$p([[:space:]/]|->)" <<< "$out" && echo "$p"
    done
}

# Status for each Dependencies menu component: ok | missing | broken | outdated
dep_status() {
    case "$1" in
        "base")
            if ! is_installed figlet && ! is_installed git && ! is_installed zsh; then
                echo "missing"
            elif ! is_installed figlet || ! is_installed git || ! is_installed zsh || ! is_installed tput; then
                echo "broken"
            elif [[ -n "$(pkg_outdated_list figlet git zsh)" ]]; then
                echo "outdated"
            else
                echo "ok"
            fi
            ;;
        "omz")
            if [[ -f "$SYS_DIR/oh-my-zsh/oh-my-zsh.sh" ]]; then
                echo "ok"
            elif [[ -d "$SYS_DIR/oh-my-zsh" ]]; then
                echo "broken"
            else
                echo "missing"
            fi
            ;;
        "plugins")
            if [[ -f "$SYS_DIR/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" &&
                  -f "$SYS_DIR/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
                echo "ok"
            elif [[ -d "$SYS_DIR/plugins" ]]; then
                echo "broken"
            else
                echo "missing"
            fi
            ;;
        "assets")
            if [[ ! -f "$SYS_DIR/assets/.draw" ]]; then
                echo "missing"
            elif ! cmp -s "$INSTALL_DIR/assets/.draw" "$SYS_DIR/assets/.draw"; then
                echo "outdated"
            else
                echo "ok"
            fi
            ;;
        "power")
            local has_eza=false has_bat=false
            if is_installed eza || is_installed exa; then has_eza=true; fi
            if is_installed bat || is_installed batcat; then has_bat=true; fi
            if [[ "$has_eza" == "true" && "$has_bat" == "true" ]]; then
                if [[ -n "$(pkg_outdated_list eza bat)" ]]; then
                    echo "outdated"
                else
                    echo "ok"
                fi
            elif [[ "$has_eza" == "true" || "$has_bat" == "true" ]]; then
                echo "broken"
            else
                echo "missing"
            fi
            ;;
        *) echo "missing" ;;
    esac
}

manage_dependencies() {
    local opts=()
    local actions=()

    # 1. Build options with live status dots (boxes always start unticked)
    opts+=("Base Packages|$(dep_status base)")
    actions+=("install_dependencies skip_power")

    opts+=("Oh-My-Zsh Framework|$(dep_status omz)")
    actions+=(install_omz)

    opts+=("Zsh Helper Plugins|$(dep_status plugins)")
    actions+=(install_plugins)

    opts+=("Promptify UI Assets|$(dep_status assets)")
    actions+=(sync_assets)

    opts+=("Others|$(dep_status power)")
    actions+=(install_power_tools)

    # 2. Run checkbox menu
    local choices
    choices=$(checkbox_menu "System Components / Repair" "" "${opts[@]}")

    [[ "$choices" == "CANCELLED" || -z "$choices" ]] && return

    # 3. Execution
    if confirm_action "Proceed with selected components?" "y"; then
        echo -e "\n\e[1;34m[*] Processing components...\e[0m"
        local ok=true
        for choice in $choices; do
            action="${actions[$choice]}"
            if [[ "$action" == "install_plugins" ]]; then
                if [[ -d "$SYS_DIR/oh-my-zsh" ]]; then
                    install_plugins || ok=false
                else
                    center_print "\e[1;31m[!] Error: Install OMZ first to enable plugins.\e[0m"
                    ok=false
                fi
            else
                $action || ok=false
            fi
        done
        if [[ "$ok" == "true" ]]; then
            press_enter "Task completed. Enter to return..."
        else
            center_print "\e[1;31m[!] Some components failed to install. See messages above.\e[0m"
            press_enter
        fi
    fi
}
