#!/bin/bash

# Dependencies live in deps/ (write-once — updates never touch them).

install_omz() {
    echo -e "\e[1;34m[*] \e[32mInstalling Oh-My-Zsh...\e[0m"
    mkdir -p "$PFY_DEPS"
    rm -rf "$PFY_DEPS_OMZ"
    git clone https://github.com/ohmyzsh/ohmyzsh.git "$PFY_DEPS_OMZ" --depth 1 \
        || { echo -e '\e[1;31m[!] Clone failed: ohmyzsh\e[0m'; return 1; }
}

install_plugins() {
    echo -e "\e[1;34m[*] \e[32mInstalling Plugins...\e[0m"
    mkdir -p "$PFY_DEPS_PLUGINS"
    rm -rf "$PFY_DEPS_PLUGINS/zsh-autosuggestions" "$PFY_DEPS_PLUGINS/zsh-syntax-highlighting"

    git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git "$PFY_DEPS_PLUGINS/zsh-autosuggestions" \
        || { echo -e '\e[1;31m[!] Clone failed: zsh-autosuggestions\e[0m'; return 1; }

    git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$PFY_DEPS_PLUGINS/zsh-syntax-highlighting" \
        || { echo -e '\e[1;31m[!] Clone failed: zsh-syntax-highlighting\e[0m'; return 1; }
}
