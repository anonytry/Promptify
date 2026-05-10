#!/bin/bash

# injects promptify core into user shell profile
setup_ui() {
    local banner_name=$1
    local theme_border=${2:-"red"}
    local theme_tag=${3:-"blue"}
    local font_pref=${4:-"auto"}
    local show_banner=${5:-"true"}

    if [[ ! -d "$SYS_DIR/oh-my-zsh" ]]; then
        return 1
    fi
    
    center_print "\e[1;34m[*] \e[32mConfiguring UI Components...\e[0m"

    local asset_dir="$INSTALL_DIR/assets"
    
    cp "$asset_dir/ASCII-Shadow.flf" "$HOME/.promptify_font.flf" || return 1
    chmod 644 "$HOME/.promptify_font.flf"

    if [[ "$OS_TYPE" == "termux" ]]; then
        mkdir -p "$HOME/.termux"
        backup_file "$HOME/.termux/colors.properties"
        backup_file "$HOME/.termux/font.ttf"
        backup_file "$HOME/.termux/termux.properties"

        cp "$asset_dir/colors.properties" "$HOME/.termux/" || true
        cp "$asset_dir/font.ttf" "$HOME/.termux/" || true
        
        # Handle different Android versions for keyboard properties
        local major_ver
        major_ver=$(echo "$ANDROID_VER" | grep -oE '^[0-9]+' || echo "0")
        if [[ "$major_ver" -gt 0 && "$major_ver" -le 7 ]]; then
            cp "$asset_dir/termux.properties2" "$HOME/.termux/termux.properties" || true
        else
            cp "$asset_dir/termux.properties" "$HOME/.termux/" || true
        fi
        
        mkdir -p "$PREFIX/share/figlet"
        cp "$asset_dir/ASCII-Shadow.flf" "$PREFIX/share/figlet/" 2>/dev/null || true
        termux-reload-settings 2>/dev/null || true
    else
        if command -v figlet &> /dev/null; then
             local figlet_dir="/usr/share/figlet"
             [[ -d "/usr/share/figlet/fonts" ]] && figlet_dir="/usr/share/figlet/fonts"
             
             if [[ ! -d "$figlet_dir" ]]; then
                 $SUDO mkdir -p "$figlet_dir" 2>/dev/null || true
             fi

             if [[ -d "$figlet_dir" ]]; then
                 $SUDO cp "$asset_dir/ASCII-Shadow.flf" "$figlet_dir/" 2>/dev/null || true
             fi
        fi
    fi

    if [[ "$show_banner" == "true" ]]; then
        cp "$asset_dir/.draw" "$HOME/.draw" 2>/dev/null || true
        chmod +x "$HOME/.draw" 2>/dev/null || true
        echo "NAME=\"$banner_name\"" > "$HOME/.username"
        echo "FONT=\"$font_pref\"" >> "$HOME/.username"
    fi

    # Ensure .zshrc exists
    [[ ! -f "$HOME/.zshrc" ]] && touch "$HOME/.zshrc"

    # Clean up old config blocks safely
    sed_i '/# --- Promptify Config ---/,/# --- End Promptify Config ---/d' "$HOME/.zshrc" 2>/dev/null

    # Only backup if not already backed up
    backup_file "$HOME/.zshrc"

    # Escape special characters in banner name to prevent shell injection/unintended expansion
    local safe_banner_name="${banner_name//\\/\\\\}"
    safe_banner_name="${safe_banner_name//\"/\\\"}"
    safe_banner_name="${safe_banner_name//\$/\\\$}"
    safe_banner_name="${safe_banner_name//\`/\\\`}"

    # Copy necessary assets to SYS_DIR for persistence
    mkdir -p "$SYS_DIR/assets"
    cp "$INSTALL_DIR/assets/ASCII-Shadow.flf" "$SYS_DIR/assets/" 2>/dev/null
    cp "$INSTALL_DIR/assets/termux.properties" "$SYS_DIR/assets/" 2>/dev/null
    cp "$INSTALL_DIR/assets/colors.properties" "$SYS_DIR/assets/" 2>/dev/null
    cp "$INSTALL_DIR/assets/font.ttf" "$SYS_DIR/assets/" 2>/dev/null

    # Prepare the banner line if enabled
    local banner_line=""
    [[ "$show_banner" == "true" ]] && banner_line="printf '\033[2J\033[H' && [[ -f ~/.draw ]] && PROMPTIFY_DIR=\"\$PROMPTIFY_DIR\" bash ~/.draw"

    cat << EOF >> "$HOME/.zshrc"

# --- Promptify Config ---
export PROMPTIFY_DIR="$SYS_DIR"
export ZSH="\$PROMPTIFY_DIR/oh-my-zsh"
ZSH_THEME=""
[[ -f \$ZSH/oh-my-zsh.sh ]] && source \$ZSH/oh-my-zsh.sh

[[ -f "\$PROMPTIFY_DIR/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && source "\$PROMPTIFY_DIR/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
[[ -f "\$PROMPTIFY_DIR/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && source "\$PROMPTIFY_DIR/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=245'

$banner_line

# Theme Variables
P_CLR_BORDER="$theme_border"
P_CLR_TAG="$theme_tag"
P_CLR_USER="green"
P_CLR_PATH="green"
P_CLR_GIT="red"

# Git Info using vcs_info for performance
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats ' %B%F{blue}(%F{red}%b%F{blue})%f'
zstyle ':vcs_info:git:*' actionformats ' %B%F{blue}(%F{red}%b|%a%F{blue})%f'

EOF

    cat << EOF >> "$HOME/.zshrc"

TNAME="$safe_banner_name"

setopt prompt_subst

build_prompt() {
    vcs_info
    local h_name="\${HOST:-termux}"
    local short_tag="\${TNAME%% *}"
    local admin_tag="%(#,%F{yellow}admin/%f,)"

    local line1="%F{\$P_CLR_BORDER}┌─[\${admin_tag}%B%F{\$P_CLR_TAG}\${short_tag:l}%F{white}@%F{\$P_CLR_USER}\${h_name}%b%F{\$P_CLR_BORDER}]─[%F{\$P_CLR_PATH}%(4~|/%2~|%~)%F{\$P_CLR_BORDER}]%f\${vcs_info_msg_0_}"
    PROMPT=\$'\n'\${line1}\$'\n%F{\$P_CLR_BORDER}└──╼ %B%F{red}❯%F{blue}❯%F{black}❯%f%b '
}

[[ -z "\${precmd_functions[(r)build_prompt]}" ]] && precmd_functions+=(build_prompt)

export LS_COLORS='rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33:cd=40;33:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32'

if command -v eza &> /dev/null; then
    alias ls='eza --icons --color=auto'
    alias ll='eza -l --icons --color=auto'
elif command -v exa &> /dev/null; then
    alias ls='exa --color=auto'
    alias ll='exa -l --color=auto'
else
    alias ls='ls --color=auto'
    alias ll='ls -l --color=auto'
fi
alias grep='grep --color=auto'
printf '\e[4 q'
# --- End Promptify Config ---
EOF

    # Handle .bashrc updates if it exists
    if [[ -f "$HOME/.bashrc" ]]; then
        sed_i '/# --- Promptify Config ---/,/# --- End Promptify Config ---/d' "$HOME/.bashrc" 2>/dev/null
        
        cat << EOF >> "$HOME/.bashrc"

# --- Promptify Config ---
export PROMPTIFY_DIR="$SYS_DIR"

# 1. Auto-start Zsh if available
if [[ -n "$BASH_VERSION" && -z "$ZSH_VERSION" && -x "$(command -v zsh)" && -t 0 ]]; then
    exec zsh
fi

# 2. Show banner ONLY if we are staying in Bash (Zsh not installed or already in Zsh)
if [[ -z "$ZSH_VERSION" ]]; then
    $banner_line
fi
# --- End Promptify Config ---
EOF
    fi

    # Automatically switch the user's login shell to Zsh if it isn't already the default
    if [[ "$SHELL" != *"zsh"* ]]; then
        local zsh_path
        zsh_path=$(command -v zsh)
        if [[ -n "$zsh_path" ]]; then
            if [[ "$OS_TYPE" == "termux" ]]; then
                chsh -s zsh 2>/dev/null || true
            else
                $SUDO chsh -s "$zsh_path" "$(whoami)" 2>/dev/null || true
            fi
        fi
    fi
}
