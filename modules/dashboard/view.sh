#!/bin/bash

draw_dashboard() {
    local b_clr="\033[1;34m" # Blue border
    local t_clr="\033[1;36m" # Title color
    local r_clr="\033[0m"
    local term_w
    term_w=$(tput cols)

    # 1. Define content lines first to calculate width
    local sys_line="System  : \033[1;32m$OS_NAME ($ARCH)\033[0m"
    local ker_line="Kernel  : \033[1;32m$KERNEL_VER\033[0m"
    local and_line=""
    [[ "$OS_TYPE" == "termux" ]] && and_line="Android : \033[1;32m$ANDROID_VER\033[0m"
    
    local s_pkgs="\033[1;32m$STATUS_PKGS\033[0m"
    local s_zsh="\033[1;32m$STATUS_ZSH\033[0m"
    local s_omz="\033[1;32m$STATUS_OMZ\033[0m"
    local s_plug="\033[1;32m$STATUS_PLUG\033[0m"
    local status_line="Status  : $s_pkgs Pkgs | $s_zsh Zsh | $s_omz OMZ | $s_plug Plug"

    # 2. Calculate required width
    local max_w=0
    for line in "$sys_line" "$ker_line" "$and_line" "$status_line"; do
        [[ -z "$line" ]] && continue
        local lw
        lw=$(get_clean_len "$line")
        [[ $lw -gt $max_w ]] && max_w=$lw
    done

    local box_w=$((max_w + 6)) # Padding
    [[ $box_w -lt 40 ]] && box_w=40
    [[ $box_w -gt $((term_w - 2)) ]] && box_w=$((term_w - 2))

    # Export for menu synchronization
    export BOX_WIDTH=$box_w

    local spacer
    spacer=$(get_spacer "$box_w")

    # 3. Draw with different style (Rounded corners)
    local title=" Dashboard "
    local total_side_len=$((box_w - 2 - ${#title}))
    local side_len=$((total_side_len / 2))
    local side_line
    side_line=$(repeat_char "─" "$side_len")
    
    local line_top="${spacer}${b_clr}╭${side_line}${t_clr}${title}${b_clr}${side_line}"
    [[ $((total_side_len % 2)) -ne 0 ]] && line_top+="─"
    line_top+="╮${r_clr}"

    local line_mid="${spacer}${b_clr}├$(repeat_char "─" $((box_w - 2)))┤${r_clr}"
    local line_bot="${spacer}${b_clr}╰$(repeat_char "─" $((box_w - 2)))╯${r_clr}"

    # Print
    printf "%b\n" "$line_top" >&2
    draw_line_single "$sys_line" "$box_w" "$b_clr" "$r_clr" "$spacer" >&2
    draw_line_single "$ker_line" "$box_w" "$b_clr" "$r_clr" "$spacer" >&2
    [[ -n "$and_line" ]] && draw_line_single "$and_line" "$box_w" "$b_clr" "$r_clr" "$spacer" >&2
    printf "%b\n" "$line_mid" >&2
    draw_line_single "$status_line" "$box_w" "$b_clr" "$r_clr" "$spacer" >&2
    printf "%b\n" "$line_bot" >&2
}

draw_line_single() {
    local content="$1"
    local box_w="$2"
    local b_clr="$3"
    local r_clr="$4"
    local offset_spacer="$5"
    
    local clean_len
    clean_len=$(get_clean_len "$content")
    local pad_len=$((box_w - clean_len - 4)) # -4 for "│ " and " │"
    
    [[ $pad_len -lt 0 ]] && pad_len=0
    
    local padding=""
    [[ $pad_len -gt 0 ]] && padding=$(printf "%${pad_len}s" "")

    printf "%b%b│ %b%s %b│%b\n" "$offset_spacer" "$b_clr" "$content" "$padding" "$b_clr" "$r_clr"
}
