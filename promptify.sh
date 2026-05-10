#!/bin/bash

# ==============================================================================
# PROMPTIFY - AOSP Style Modular Shell Customizer
# ==============================================================================

# 1. Mode Detection (Local vs Remote Bootstrap)
REPO_URL="https://github.com/TopexGuy/promptify.git"
IS_LOCAL=false
CONFIRM_ALL=false
SILENT_MODE=false

# Parse flags
for arg in "$@"; do
    case "$arg" in
        --local) IS_LOCAL=true ;;
        --yes|-y) CONFIRM_ALL=true ;;
        --silent|-s) SILENT_MODE=true; CONFIRM_ALL=true ;;
    esac
done

if [[ "$IS_LOCAL" == "false" ]]; then
    if [[ -f "promptify.sh" && -d "core" ]]; then
        IS_LOCAL=true
    elif [[ -n "${BASH_SOURCE[0]}" ]]; then
        _S_PATH="${BASH_SOURCE[0]}"
        if [[ -f "$_S_PATH" ]]; then
            _S_DIR="$(cd "$(dirname "$_S_PATH")" && pwd 2>/dev/null)"
            if [[ -f "$_S_DIR/promptify.sh" && -d "$_S_DIR/core" ]]; then
                IS_LOCAL=true
                INSTALL_DIR="$_S_DIR"
            fi
        fi
    fi
fi

if [[ "$IS_LOCAL" == "true" ]]; then
    INSTALL_DIR="${INSTALL_DIR:-$(pwd)}"
fi

# 2. Remote Bootstrap Execution
if [[ "$IS_LOCAL" == "false" ]]; then
    INSTALL_DIR="$(pwd)/promptify"
    
    [[ "$SILENT_MODE" == "false" ]] && echo -e "\e[1;34m[*] Promptify: Bootstrap Mode\e[0m"
    
    if [[ -d "$INSTALL_DIR" ]]; then
        if [[ "$CONFIRM_ALL" == "true" ]]; then
            CONF_RECLONE="y"
        else
            echo -ne " \e[1;33m[!] Directory '$INSTALL_DIR' already exists. Overwrite? (y/N): \e[0m"
            read -r CONF_RECLONE
        fi

        if [[ "$CONF_RECLONE" != [Y/y] ]]; then
            echo -e " \e[1;31m[!] Aborting.\e[0m"
            exit 1
        fi
        rm -rf "$INSTALL_DIR"
    fi
    
    [[ "$SILENT_MODE" == "false" ]] && echo -e " \e[1;34m[*] Cloning Promptify into $INSTALL_DIR...\e[0m"
    git clone --depth 1 "$REPO_URL" "$INSTALL_DIR" || { echo "Clone failed."; exit 1; }
    
    cd "$INSTALL_DIR" || exit 1
    
    # Pass flags to local execution
    ARGS=("--local")
    [[ "$CONFIRM_ALL" == "true" ]] && ARGS+=("--yes")
    [[ "$SILENT_MODE" == "true" ]] && ARGS+=("--silent")
    
    exec bash "promptify.sh" "${ARGS[@]}"
    exit
fi

# 2.5 Pre-Execution Checks
if [[ ! -w "$HOME" ]]; then
    echo -e "\e[1;31m[!] Error: No write permission in HOME directory ($HOME).\e[0m"
    exit 1
fi

if [[ "$IS_LOCAL" == "true" && ! -w "$(pwd)" ]]; then
    echo -e "\e[1;31m[!] Error: No write permission in current directory ($(pwd)).\e[0m"
    exit 1
fi

export INSTALL_DIR
export SYS_DIR="$HOME/.promptify"
export CONFIRM_ALL
export SILENT_MODE

# 3. Modular Bootloader (Sourcing all components)
BOOT_DIRS=("core/env" "core/utils" "core/install" "core/ui" "core/maintenance" "modules/dashboard" "modules/setup" "modules/customization")

for dir in "${BOOT_DIRS[@]}"; do
    for file in "$INSTALL_DIR/$dir"/*.sh; do
        # shellcheck disable=SC1090
        [[ -f "$file" ]] && source "$file"
    done
done

source "$INSTALL_DIR/core/env/version.sh"

# 4. Global State & Signal Handling
trap ':' SIGINT SIGTERM
trap 'tput cnorm' EXIT

# UI Width Calculation for perfect alignment
calculate_ui_width() {
    local name="${BANNER_NAME:-Promptify}"
    local fig_w=0
    if command -v figlet &> /dev/null; then
        fig_w=$(figlet -f "standard" "$name" | awk '{ if (length > max) max = length } END { print max }')
    else
        fig_w=${#name}
    fi
    export BOX_WIDTH=$((fig_w + 10))
    [[ $BOX_WIDTH -lt 40 ]] && export BOX_WIDTH=40
    local term_w
    term_w=$(tput cols)
    [[ $BOX_WIDTH -gt $((term_w - 2)) ]] && export BOX_WIDTH=$((term_w - 2))
}

# shellcheck disable=SC2034
RESIZED=true
trap 'RESIZED=true' SIGWINCH
detect_env
# shellcheck disable=SC2034
CUR_THEME_BORDER="red"
# shellcheck disable=SC2034
CUR_THEME_TAG="blue"
# shellcheck disable=SC2034
CUR_FONT="auto"
# shellcheck disable=SC2034
BANNER_NAME="Promptify"
# shellcheck disable=SC2034
USE_BANNER="true"
load_prefs
calculate_ui_width

update_status() {
    # shellcheck disable=SC2034
    STATUS_ZSH=$(check_status "zsh")
    # shellcheck disable=SC2034
    STATUS_PKGS=$(check_status "figlet" "ruby" "git" "lolcat")
    # shellcheck disable=SC2034
    STATUS_OMZ=$(check_path "$SYS_DIR/oh-my-zsh")
    # shellcheck disable=SC2034
    STATUS_PLUG=$(check_path "$SYS_DIR/plugins/zsh-autosuggestions")
}

update_status

# 5. Main Loop
while true; do
    if [[ "$RESIZED" == "true" ]]; then
        calculate_ui_width
        RESIZED=false
    fi
    
    MAIN_CHOICE=$(radio_menu "Promptify v${VERSION}" "draw_dashboard" "" \
        "Quick Setup" \
        "Reload & Apply UI" \
        "Customization" \
        "Dependencies" \
        "Updates" \
        "Uninstall" \
        "Exit")

    case "$MAIN_CHOICE" in
        "CANCELLED") 
            confirm_action "Exit Promptify?" && exit_script
            continue 
            ;;
        0) guided_setup; update_status ;;
        1)
            check_setup || continue
            refresh_ui
            center_print "\e[1;32m[✔] Changes Applied!\e[0m"
            restart_shell
            ;;
        2) 
            check_setup || continue
            manage_customization 
            ;;
        3) 
            check_setup || continue
            manage_dependencies; update_status 
            ;;
        4) check_updates; update_status ;;
        5) uninstall_promptify ;;
        6) 
            if confirm_action "Exit Promptify?" "y"; then
                exit_script
            fi
            ;;
    esac
done
