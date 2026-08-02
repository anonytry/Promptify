#!/bin/bash

# Create global binary
create_global_binary() {
    local bin_path="/usr/local/bin/promptify"
    [[ "$OS_TYPE" == "termux" ]] && bin_path="$PREFIX/bin/promptify"
    
    local target_script="$SYS_DIR/promptify.sh"

    # Idempotent: if the wrapper already exists and points at the right target,
    # skip entirely (no sudo prompt on every local apply).
    if [[ -f "$bin_path" ]] && grep -qF "bash \"$target_script\"" "$bin_path" 2>/dev/null; then
        return 0
    fi
    
    # Wrapper script
    cat << EOF > promptify_wrapper
#!/bin/bash
bash "$target_script" --local "\$@"
EOF
    
    if [[ "$OS_TYPE" == "termux" ]]; then
        mv promptify_wrapper "$bin_path" 2>/dev/null || {
            # Permission fallback
            cat promptify_wrapper > "$bin_path" 2>/dev/null
        }
        chmod +x "$bin_path" 2>/dev/null
    else
        # Sudo fallback
        $SUDO mv promptify_wrapper "$bin_path" 2>/dev/null
        $SUDO chmod +x "$bin_path" 2>/dev/null
    fi
    rm -f promptify_wrapper
}

# Inject UI profile
setup_ui() {
    local banner_name=$1
    local theme_border=${2:-"red"}
    local theme_tag=${3:-"blue"}
    local font_pref=${4:-"random"}
    local show_banner=${5:-"true"}
    local prompt_style=${6:-"parrot"}
    local cat_style="${CUR_CAT_STYLE:-full}"

    if [[ ! -d "$SYS_DIR/oh-my-zsh" ]]; then
        return 1
    fi
    
    center_print "\e[1;34m[*] \e[32mConfiguring UI Components...\e[0m"

    local asset_dir="$INSTALL_DIR/assets"
    
    # Bundled banner fonts (shadow + the extra lowercase-capable styles)
    local bundled_fonts=("ASCII-Shadow.flf" "slant.flf" "banner.flf" "smpoison.flf" "graffiti.flf")
    
    cp "$asset_dir/ASCII-Shadow.flf" "$HOME/.promptify_font.flf" || return 1
    chmod 644 "$HOME/.promptify_font.flf"

    if [[ "$OS_TYPE" == "termux" ]]; then
        mkdir -p "$HOME/.termux"
        backup_file "$HOME/.termux/colors.properties"
        backup_file "$HOME/.termux/font.ttf"
        backup_file "$HOME/.termux/termux.properties"

        cp "$asset_dir/colors.properties" "$HOME/.termux/" || true
        cp "$asset_dir/font.ttf" "$HOME/.termux/" || true
        
        # Android properties
        local major_ver
        major_ver=$(echo "$ANDROID_VER" | grep -oE '^[0-9]+' || echo "0")
        if [[ "$major_ver" -gt 0 && "$major_ver" -le 7 ]]; then
            cp "$asset_dir/termux.properties2" "$HOME/.termux/termux.properties" || true
        else
            cp "$asset_dir/termux.properties" "$HOME/.termux/" || true
        fi
        
        mkdir -p "$PREFIX/share/figlet"
        for font_file in "${bundled_fonts[@]}"; do
            cp "$asset_dir/$font_file" "$PREFIX/share/figlet/" 2>/dev/null || true
        done
        termux-reload-settings 2>/dev/null || true
    else
        if command -v figlet &> /dev/null; then
             local figlet_dir="/usr/share/figlet"
             [[ -d "/usr/share/figlet/fonts" ]] && figlet_dir="/usr/share/figlet/fonts"
             
             if [[ ! -d "$figlet_dir" ]]; then
                 $SUDO mkdir -p "$figlet_dir" 2>/dev/null || true
             fi

             if [[ -d "$figlet_dir" ]]; then
                 for font_file in "${bundled_fonts[@]}"; do
                     $SUDO cp "$asset_dir/$font_file" "$figlet_dir/" 2>/dev/null || true
                 done
             fi
        fi

        # Install Nerd Font + auto-set it in common desktop terminals
        apply_desktop_font
    fi

    if [[ "$show_banner" == "true" ]]; then
        cp "$asset_dir/.draw" "$HOME/.draw" 2>/dev/null || true
        chmod +x "$HOME/.draw" 2>/dev/null || true
        set_username_pref NAME "$banner_name"
        set_username_pref FONT "$font_pref"
        set_username_pref STYLE "$prompt_style"
    else
        # Drop any stale banner so load_prefs infers USE_BANNER=false consistently
        rm -f "$HOME/.draw"
        if [[ -f "$HOME/.username" ]]; then
            sed_i '/^NAME=/d; /^FONT=/d' "$HOME/.username" 2>/dev/null
            if [[ ! -s "$HOME/.username" ]] || ! grep -qE '^[A-Z_]+=' "$HOME/.username"; then
                rm -f "$HOME/.username"
            fi
        fi
    fi

    # Clean old config robustly
    if [[ -f "$HOME/.zshrc" ]]; then
        sed_i '/# --- Promptify Config ---/,/# --- End Promptify Config ---/d' "$HOME/.zshrc" 2>/dev/null
        # Second pass for orphaned variables if markers were broken
        sed_i '/PROMPTIFY_DIR=/d' "$HOME/.zshrc" 2>/dev/null
    else
        touch "$HOME/.zshrc"
    fi

    # Backup profile
    backup_file "$HOME/.zshrc"

    # Escape banner name
    local safe_banner_name="${banner_name//\\/\\\\}"
    safe_banner_name="${safe_banner_name//\"/\\\"}"
    safe_banner_name="${safe_banner_name//\$/\\\$}"
    safe_banner_name="${safe_banner_name//\`/\\\`}"

    # Persist assets
    mkdir -p "$SYS_DIR/assets"
    for font_file in "${bundled_fonts[@]}"; do
        cp "$INSTALL_DIR/assets/$font_file" "$SYS_DIR/assets/" 2>/dev/null
    done
    cp "$INSTALL_DIR/assets/termux.properties" "$SYS_DIR/assets/" 2>/dev/null
    cp "$INSTALL_DIR/assets/colors.properties" "$SYS_DIR/assets/" 2>/dev/null
    cp "$INSTALL_DIR/assets/font.ttf" "$SYS_DIR/assets/" 2>/dev/null
    
    # Create global command
    create_global_binary

    # Setup aliases block
    local aliases_content
    aliases_content=$(cat << EOF
if command -v eza &> /dev/null; then
    alias ls='eza --icons --color=auto'
    alias ll='eza -l --icons --color=auto'
    alias l='eza --icons'
elif command -v exa &> /dev/null; then
    alias ls='exa --color=auto'
    alias ll='exa -l --color=auto'
    alias l='exa'
else
    alias ls='ls --color=auto'
    alias ll='ls -l --color=auto'
    alias l='ls'
fi

if command -v bat &>/dev/null; then
    alias cat='bat --style=$cat_style --paging=never --color=always'
elif command -v batcat &>/dev/null; then
    alias cat='batcat --style=$cat_style --paging=never --color=always'
fi

alias Promptify='promptify'
alias pty='promptify'
alias grep='grep --color=auto'
EOF
)

    # Setup banner exec
    local banner_line=""
    [[ "$show_banner" == "true" ]] && banner_line="printf '\033[2J\033[H' && [[ -f ~/.draw ]] && PROMPTIFY_DIR=\"\$PROMPTIFY_DIR\" bash ~/.draw"

    # Build the zsh profile block into a temp file and syntax-check it before
    # touching the real ~/.zshrc (a heredoc typo must never break the login shell).
    local zshrc_add
    zshrc_add=$(mktemp)

    cat << EOF >> "$zshrc_add"

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

# Git Info
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats ' %B%F{blue}(%F{red}%b%F{blue})%f'
zstyle ':vcs_info:git:*' actionformats ' %B%F{blue}(%F{red}%b|%a%F{blue})%f'

EOF

    cat << EOF >> "$zshrc_add"

TNAME="$safe_banner_name"

EOF

    get_prompt_block "$prompt_style" >> "$zshrc_add"

    cat << EOF >> "$zshrc_add"

export LS_COLORS='rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33:cd=40;33:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32'

$aliases_content
printf '\e[4 q'
# --- End Promptify Config ---
EOF

    # Syntax-check the generated block before installing it
    if command -v zsh &> /dev/null && ! zsh -n "$zshrc_add" 2>/dev/null; then
        center_print "\e[1;31m[!] Generated zsh config failed validation. Not applying.\e[0m"
        rm -f "$zshrc_add"
        return 1
    fi
    cat "$zshrc_add" >> "$HOME/.zshrc"
    rm -f "$zshrc_add"

    # Update .bashrc
    [[ ! -f "$HOME/.bashrc" ]] && touch "$HOME/.bashrc"
    
    sed_i '/# --- Promptify Config ---/,/# --- End Promptify Config ---/d' "$HOME/.bashrc" 2>/dev/null
    
    cat << EOF >> "$HOME/.bashrc"

# --- Promptify Config ---
export PROMPTIFY_DIR="$SYS_DIR"

# 1. Auto-start Zsh if available
if [[ -n "$BASH_VERSION" && -z "$ZSH_VERSION" && -x "$(command -v zsh)" && -t 0 ]]; then
    exec zsh
fi

# Show banner if staying in Bash
if [[ -z "$ZSH_VERSION" ]]; then
    $banner_line
fi

$aliases_content
# --- End Promptify Config ---
EOF

    # Switch default shell to Zsh
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
