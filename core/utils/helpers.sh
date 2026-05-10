#!/bin/bash

repeat_char() {
    local char="$1"
    local count="$2"
    local result
    if [[ $count -gt 0 ]]; then
        printf -v result "%*s" "$count" ""
        echo -n "${result// /$char}"
    fi
}

# Robust version of get_clean_len using sed to avoid greedy glob issues
get_clean_len() {
    local text="$1"
    # Remove ANSI escape sequences precisely using sed
    local clean
    clean=$(printf "%b" "$text" | sed "s/\x1B\[\([0-9]\{1,3\}\(;[0-9]\{1,3\}\)*\)\?[mGK]//g")
    echo -n "${#clean}"
}

# Robust backup function
backup_file() {
    local file="$1"
    local backup_ext="${2:-.bak}"
    local backup_path="${file}${backup_ext}"
    
    if [[ -f "$file" ]]; then
        if [[ ! -f "$backup_path" ]]; then
            cp "$file" "$backup_path"
            # Silently backup unless in debug/verbose (not implemented here)
        fi
    fi
}

check_status() {
    local all_found=true
    local cmd
    for cmd in "$@"; do
        if ! command -v "$cmd" &> /dev/null; then
            all_found=false
            break
        fi
    done
    [[ "$all_found" == true ]] && printf "\033[1;32m✔\033[0m" || printf "\033[1;31m✘\033[0m"
}

check_path() {
    local all_found=true
    local p
    for p in "$@"; do
        if [[ ! -d "$p" && ! -f "$p" ]]; then
            all_found=false
            break
        fi
    done
    [[ "$all_found" == true ]] && printf "\033[1;32m✔\033[0m" || printf "\033[1;31m✘\033[0m"
}

is_promptify_installed() {
    [[ -f "$HOME/.zshrc" ]] && grep -q "# --- Promptify Config ---" "$HOME/.zshrc" 2>/dev/null
}

check_setup() {
    if [[ ! -d "$SYS_DIR/oh-my-zsh" ]]; then
        echo -e " \e[1;31m[!] Error: Run Quick Setup first.\e[0m"
        press_enter
        return 1
    fi
    return 0
}

draw_separator() {
    local width="$1"
    local spacer="$2"
    local char="${3:-─}"
    local line
    if [[ -n "$width" ]]; then
        line=$(repeat_char "$char" "$width")
    else
        local term_w
        term_w=$(tput cols 2>/dev/null || echo 80)
        line=$(repeat_char "$char" "$((term_w - 2))")
    fi
    printf "%b\e[1;30m%s\e[0m\n" "$spacer" "$line"
}

get_spacer() {
    local width="$1"
    local term_w
    term_w=$(tput cols 2>/dev/null || echo 80)
    local offset=$(( (term_w - width) / 2 ))
    [[ $offset -lt 0 ]] && offset=0
    printf "%${offset}s" ""
}

center_print() {
    local text="$1"
    local clean_len
    clean_len=$(get_clean_len "$text")
    local spacer
    spacer=$(get_spacer "$clean_len")
    printf "\r%b%b\033[0m\033[K\n" "$spacer" "$text"
}

# Portable sed -i
sed_i() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

draw_line() {
    local content="$1"
    local box_w="$2"
    local b_clr="$3"
    local r_clr="$4"
    local offset_spacer="$5"
    
    local clean_len
    clean_len=$(get_clean_len "$content")
    local total_pad=$((box_w - clean_len - 4)) # -4 for "║ " and " ║"
    [[ $total_pad -lt 0 ]] && total_pad=0

    local pad_l=$((total_pad / 2))
    local pad_r=$((total_pad - pad_l))
    
    local padding_l=""
    local padding_r=""
    [[ $pad_l -gt 0 ]] && padding_l=$(printf "%${pad_l}s" "")
    [[ $pad_r -gt 0 ]] && padding_r=$(printf "%${pad_r}s" "")

    # Use %b for content to interpret escapes and colors
    printf "%b%b║ %s%b%s %b║%b\n" "$offset_spacer" "$b_clr" "$padding_l" "$content" "$padding_r" "$b_clr" "$r_clr"
}
