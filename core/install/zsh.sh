#!/bin/bash

install_omz() {
    echo -e "\e[1;34m[*] \e[32mInstalling Oh-My-Zsh...\e[0m"
    mkdir -p "$SYS_DIR"
    rm -rf "$SYS_DIR/oh-my-zsh"
    git clone https://github.com/ohmyzsh/ohmyzsh.git "$SYS_DIR/oh-my-zsh" --depth 1 \
        || { echo -e '\e[1;31m[!] Clone failed: ohmyzsh\e[0m'; return 1; }
}

install_plugins() {
    echo -e "\e[1;34m[*] \e[32mInstalling Plugins...\e[0m"
    mkdir -p "$SYS_DIR/plugins"
    rm -rf "$SYS_DIR/plugins/zsh-autosuggestions" "$SYS_DIR/plugins/zsh-syntax-highlighting"
    
    git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git "$SYS_DIR/plugins/zsh-autosuggestions" \
        || { echo -e '\e[1;31m[!] Clone failed: zsh-autosuggestions\e[0m'; return 1; }
        
    git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$SYS_DIR/plugins/zsh-syntax-highlighting" \
        || { echo -e '\e[1;31m[!] Clone failed: zsh-syntax-highlighting\e[0m'; return 1; }
}
