#!/bin/bash

manage_dependencies() {
    local opts=()
    local actions=()

    # 1. Build options (pre-select if already installed/missing as appropriate)
    opts+=("Base Packages (git, zsh, etc.)|selected")
    actions+=(install_dependencies)

    opts+=("Oh-My-Zsh Framework|selected")
    actions+=(install_omz)

    opts+=("Zsh Helper Plugins|selected")
    actions+=(install_plugins)

    opts+=("Promptify UI Assets|selected")
    actions+=(sync_assets)

    # Others (Eza/Bat): pre-select only if some are missing
    local power_sel=""
    if ! is_installed eza && ! is_installed exa && ! is_installed bat && ! is_installed batcat; then
        power_sel="|selected"
    fi
    opts+=("Others (Eza, Bat)$power_sel")
    actions+=(install_power_tools)

    # 2. Run checkbox menu
    local choices
    choices=$(checkbox_menu "System Components / Repair" "${opts[@]}")

    [[ "$choices" == "CANCELLED" || -z "$choices" ]] && return

    # 3. Execution
    if confirm_action "Proceed with selected components?" "y"; then
        echo -e "\n\e[1;34m[*] Processing components...\e[0m"
        for choice in $choices; do
            action="${actions[$choice]}"
            if [[ "$action" == "install_plugins" ]]; then
                if [[ -d "$SYS_DIR/oh-my-zsh" ]]; then
                    install_plugins
                else
                    center_print "\e[1;31m[!] Error: Install OMZ first to enable plugins.\e[0m"
                fi
            else
                $action
            fi
        done
        press_enter "Task completed. Enter to return..."
    fi
}
