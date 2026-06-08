#!/bin/bash
# PROMPTIFY

# 1. Mode Detection 
REPO_URL="https://github.com/TopexGuy/promptify.git"
IS_LOCAL=false
CONFIRM_ALL=false
SILENT_MODE=false

# Resolve script path
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# Parse flags
for arg in "$@"; do
    case "$arg" in
        --local) IS_LOCAL=true ;;
        --yes|-y) CONFIRM_ALL=true ;;
        --silent|-s) SILENT_MODE=true; CONFIRM_ALL=true ;;
    esac
done

if [[ -f "$SCRIPT_DIR/promptify.sh" && -d "$SCRIPT_DIR/core" ]]; then
    INSTALL_DIR="$SCRIPT_DIR"
elif [[ -f "promptify.sh" && -d "core" ]]; then
    INSTALL_DIR="$(pwd)"
fi

if [[ "$IS_LOCAL" == "false" ]]; then
    if [[ -n "$INSTALL_DIR" ]]; then
        IS_LOCAL=true
    fi
fi

# 2. Remote Bootstrap Execution
if [[ "$IS_LOCAL" == "false" ]]; then
    INSTALL_DIR="$(pwd)/promptify"
    
    [[ "$SILENT_MODE" == "false" ]] && echo -e "\e[1;34m[*] Promptify: Bootstrap Mode\e[0m"

    # Ensure git
    if ! command -v git &>/dev/null; then
        [[ "$SILENT_MODE" == "false" ]] && echo -ne "\e[1;34m[*] Installing git...\e[0m"
        if [[ -d "/data/data/com.termux/files/usr/bin" ]]; then
            pkg install git -y &>/dev/null
        elif command -v apt &>/dev/null; then
            sudo apt update -y &>/dev/null
            sudo apt install git -y &>/dev/null
        fi
        [[ "$SILENT_MODE" == "false" ]] && echo -e " \e[1;32mDone.\e[0m"
    fi
    
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
    
    # Pass flags to local exec
    ARGS=("--local")
    [[ "$CONFIRM_ALL" == "true" ]] && ARGS+=("--yes")
    [[ "$SILENT_MODE" == "true" ]] && ARGS+=("--silent")
    
    exec bash "promptify.sh" "${ARGS[@]}"
    exit
fi

# 2.5 Universal Bootstrap
# Load detection early
source "$INSTALL_DIR/core/env/detect.sh"
detect_env

if [[ "$IS_LOCAL" == "true" ]]; then
    # Bootstrap core tools
    if ! command -v tput &>/dev/null || ! command -v git &>/dev/null; then
        [[ "$SILENT_MODE" == "false" ]] && echo -ne "\e[1;34m[*] Installing core dependencies for your system...\e[0m"
        
        case $PKG_MNGR in
            pkg) pkg install ncurses-utils git -y &>/dev/null ;;
            apt) $SUDO apt update -y &>/dev/null && $SUDO apt install ncurses-bin git -y &>/dev/null ;;
            pacman) $SUDO pacman -Sy --noconfirm ncurses git &>/dev/null ;;
            dnf) $SUDO dnf install -y ncurses git &>/dev/null ;;
            zypper) $SUDO zypper install -y ncurses git &>/dev/null ;;
            apk) $SUDO apk add ncurses git &>/dev/null ;;
            brew) brew install ncurses git &>/dev/null ;;
        esac
        [[ "$SILENT_MODE" == "false" ]] && echo -e " \e[1;32mDone.\e[0m"
    fi
fi

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
        # Skip pre-sourced detect.sh
        [[ "$file" == *"core/env/detect.sh" ]] && continue
        [[ -f "$file" ]] && source "$file"
    done
done

source "$INSTALL_DIR/core/env/version.sh"

# 4. Global State & Signal Handling
trap ':' SIGINT SIGTERM
trap 'tput cnorm' EXIT

# Calculate UI width
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
    STATUS_PKGS=$(check_status "figlet" "git" "lolcat")
    # shellcheck disable=SC2034
    STATUS_OMZ=$(check_path "$SYS_DIR/oh-my-zsh")
    # shellcheck disable=SC2034
    STATUS_PLUG=$(check_path "$SYS_DIR/plugins/zsh-autosuggestions")
}

update_status

# 4.5 Smart First-Run Trigger
if ! is_promptify_installed; then
    clear
    promptify_header
    echo -e "\n\e[1;34m[!] Welcome to Promptify!\e[0m"
    echo -e "\e[1;33m[*] It looks like Promptify isn't configured yet.\e[0m"
    if confirm_action "Start Guided Setup Wizard?" "y"; then
        guided_setup
        update_status
    fi
fi

# 5. Main Loop
while true; do
    # Real-time sync
    load_prefs
    if [[ "$RESIZED" == "true" ]]; then
        calculate_ui_width
        RESIZED=false
    fi
    
    MAIN_CHOICE=$(radio_menu "Promptify v${VERSION}" "draw_dashboard" "" 0 -1 \
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
